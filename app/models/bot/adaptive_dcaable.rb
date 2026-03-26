module Bot::AdaptiveDcaable
  extend ActiveSupport::Concern

  ADAPTIVE_DCA_AGGRESSIVENESS_LEVELS = {
    'conservative' => 0.3,
    'moderate' => 0.7,
    'aggressive' => 1.2
  }.freeze

  ADAPTIVE_DCA_DEFAULT_FLOOR_PCT = 30
  ADAPTIVE_DCA_DEFAULT_CEILING_PCT = 250
  ADAPTIVE_DCA_DEFAULT_AGGRESSIVENESS = 'moderate'

  # EWMA parameters
  LAMBDA_FAST = 0.10   # ~7h raw half-life, ~5h effective with DEMA
  LAMBDA_SLOW = 0.005  # ~6d half-life with hourly observations
  FAST_WEIGHT = 0.4
  SLOW_WEIGHT = 0.6
  INITIAL_SIGMA_FRACTION = 0.02 # Initialize σ as 2% of price

  included do
    store_accessor :settings,
                   :adaptive_dca_enabled,
                   :adaptive_dca_aggressiveness,
                   :adaptive_dca_floor_pct,
                   :adaptive_dca_ceiling_pct

    store_accessor :transient_data,
                   :adaptive_mu_fast,
                   :adaptive_sigma_sq_fast,
                   :adaptive_ema2_fast,
                   :adaptive_mu_slow,
                   :adaptive_sigma_sq_slow

    after_initialize :initialize_adaptive_dca_settings
    before_save :handle_adaptive_dca_toggle, if: :will_save_change_to_settings?

    decorators = Module.new do
      def parse_params(params)
        super(params).merge(
          adaptive_dca_enabled: params[:adaptive_dca_enabled].presence&.in?(%w[1 true]),
          adaptive_dca_aggressiveness: params[:adaptive_dca_aggressiveness].presence,
          adaptive_dca_floor_pct: params[:adaptive_dca_floor_pct].presence&.to_i,
          adaptive_dca_ceiling_pct: params[:adaptive_dca_ceiling_pct].presence&.to_i
        ).compact
      end

      def effective_quote_amount
        return super unless adaptive_dca_enabled?

        (quote_amount.to_f / 24.0) * adaptive_multiplier
      end

      def effective_interval_duration
        return super unless adaptive_dca_enabled?

        1.hour
      end
    end

    prepend decorators
  end

  def adaptive_dca_enabled?
    adaptive_dca_enabled == true
  end

  def adaptive_dca_cold_start?
    adaptive_mu_fast.blank?
  end

  def adaptive_multiplier
    return 1.0 unless adaptive_dca_enabled?
    return 1.0 if adaptive_dca_cold_start?

    z = adaptive_z_score
    k = ADAPTIVE_DCA_AGGRESSIVENESS_LEVELS[adaptive_dca_aggressiveness] ||
        ADAPTIVE_DCA_AGGRESSIVENESS_LEVELS[ADAPTIVE_DCA_DEFAULT_AGGRESSIVENESS]

    multiplier = Math.exp(-k * z)

    floor = (adaptive_dca_floor_pct || ADAPTIVE_DCA_DEFAULT_FLOOR_PCT).to_f / 100.0
    ceiling = (adaptive_dca_ceiling_pct || ADAPTIVE_DCA_DEFAULT_CEILING_PCT).to_f / 100.0

    multiplier.clamp(floor, ceiling)
  end

  def adaptive_z_score
    return 0.0 if adaptive_dca_cold_start?

    mu = blended_mu
    sigma = blended_sigma
    return 0.0 if sigma.zero?

    (current_adaptive_price - mu) / sigma
  end

  def update_adaptive_ewma!(price)
    price = price.to_f

    if adaptive_dca_cold_start?
      initialize_adaptive_ewma!(price)
    else
      mu_f = adaptive_mu_fast.to_f
      sq_f = adaptive_sigma_sq_fast.to_f
      ema2_f = adaptive_ema2_fast.to_f
      mu_s = adaptive_mu_slow.to_f
      sq_s = adaptive_sigma_sq_slow.to_f

      # Fast EWMA update
      self.adaptive_mu_fast = (LAMBDA_FAST * price + (1 - LAMBDA_FAST) * mu_f).to_s
      self.adaptive_sigma_sq_fast = (LAMBDA_FAST * (price - adaptive_mu_fast.to_f)**2 +
                                     (1 - LAMBDA_FAST) * sq_f).to_s
      # DEMA: EMA of the fast EMA (for lag compensation)
      self.adaptive_ema2_fast = (LAMBDA_FAST * adaptive_mu_fast.to_f + (1 - LAMBDA_FAST) * ema2_f).to_s

      # Slow EWMA update
      self.adaptive_mu_slow = (LAMBDA_SLOW * price + (1 - LAMBDA_SLOW) * mu_s).to_s
      self.adaptive_sigma_sq_slow = (LAMBDA_SLOW * (price - adaptive_mu_slow.to_f)**2 +
                                     (1 - LAMBDA_SLOW) * sq_s).to_s
    end

    @current_adaptive_price = price
  end

  def clear_adaptive_ewma_state!
    self.adaptive_mu_fast = nil
    self.adaptive_sigma_sq_fast = nil
    self.adaptive_ema2_fast = nil
    self.adaptive_mu_slow = nil
    self.adaptive_sigma_sq_slow = nil
    @current_adaptive_price = nil
  end

  def blended_mu
    # DEMA on fast component: 2*EMA - EMA(EMA) for lag compensation
    dema_fast = 2.0 * adaptive_mu_fast.to_f - adaptive_ema2_fast.to_f
    FAST_WEIGHT * dema_fast + SLOW_WEIGHT * adaptive_mu_slow.to_f
  end

  def blended_sigma
    variance = FAST_WEIGHT * adaptive_sigma_sq_fast.to_f + SLOW_WEIGHT * adaptive_sigma_sq_slow.to_f
    Math.sqrt([variance, 0].max)
  end

  def adaptive_dca_status
    return nil unless adaptive_dca_enabled?

    if adaptive_dca_cold_start?
      { enabled: true, cold_start: true }
    else
      baseline_hourly = quote_amount.to_f / 24.0
      multiplier = adaptive_multiplier
      {
        enabled: true,
        cold_start: false,
        current_multiplier: multiplier.round(3),
        effective_hourly_amount: (baseline_hourly * multiplier).round(8),
        baseline_hourly_amount: baseline_hourly.round(8),
        ewma_belief_price: blended_mu.round(8),
        z_score: adaptive_z_score.round(3),
        aggressiveness: adaptive_dca_aggressiveness || ADAPTIVE_DCA_DEFAULT_AGGRESSIVENESS,
        floor_pct: (adaptive_dca_floor_pct || ADAPTIVE_DCA_DEFAULT_FLOOR_PCT).to_i,
        ceiling_pct: (adaptive_dca_ceiling_pct || ADAPTIVE_DCA_DEFAULT_CEILING_PCT).to_i
      }
    end
  end

  private

  def current_adaptive_price
    @current_adaptive_price || blended_mu
  end

  def initialize_adaptive_ewma!(price)
    avg_price = fetch_24h_average_price
    belief_price = avg_price || price

    initial_sigma_sq = if avg_price && @_24h_prices&.length&.>(1)
                         @_24h_prices.sum { |p| (p - belief_price)**2 } / @_24h_prices.length
                       else
                         (price * INITIAL_SIGMA_FRACTION)**2
                       end

    self.adaptive_mu_fast = belief_price.to_s
    self.adaptive_sigma_sq_fast = initial_sigma_sq.to_s
    self.adaptive_ema2_fast = belief_price.to_s
    self.adaptive_mu_slow = belief_price.to_s
    self.adaptive_sigma_sq_slow = initial_sigma_sq.to_s
    @current_adaptive_price = price
  end

  def fetch_24h_average_price
    return nil unless respond_to?(:ticker) && ticker.present?

    result = ticker.get_candles(start_at: 24.hours.ago, timeframe: 1.hour)
    return nil if result.failure?

    candles = result.data
    return nil if candles.blank?

    @_24h_prices = candles.map { |c| c[4].to_f }
    @_24h_prices.sum / @_24h_prices.length
  rescue StandardError => e
    Rails.logger.warn("Adaptive DCA: failed to fetch 24h candles for cold start seeding: #{e.message}")
    nil
  end

  def seed_adaptive_ewma_from_market!
    avg_price = fetch_24h_average_price
    return unless avg_price

    initial_sigma_sq = if @_24h_prices&.length&.>(1)
                         @_24h_prices.sum { |p| (p - avg_price)**2 } / @_24h_prices.length
                       else
                         (avg_price * INITIAL_SIGMA_FRACTION)**2
                       end

    self.adaptive_mu_fast = avg_price.to_s
    self.adaptive_sigma_sq_fast = initial_sigma_sq.to_s
    self.adaptive_ema2_fast = avg_price.to_s
    self.adaptive_mu_slow = avg_price.to_s
    self.adaptive_sigma_sq_slow = initial_sigma_sq.to_s
  end

  def initialize_adaptive_dca_settings
    self.adaptive_dca_enabled ||= false
    self.adaptive_dca_aggressiveness ||= ADAPTIVE_DCA_DEFAULT_AGGRESSIVENESS
    self.adaptive_dca_floor_pct ||= ADAPTIVE_DCA_DEFAULT_FLOOR_PCT
    self.adaptive_dca_ceiling_pct ||= ADAPTIVE_DCA_DEFAULT_CEILING_PCT
  end

  def handle_adaptive_dca_toggle
    return if adaptive_dca_enabled_was == adaptive_dca_enabled

    if adaptive_dca_enabled?
      # Auto-disable smart intervals (mutual exclusivity)
      self.smart_intervaled = false if respond_to?(:smart_intervaled=)
      # Ensure defaults
      self.adaptive_dca_aggressiveness = ADAPTIVE_DCA_DEFAULT_AGGRESSIVENESS if adaptive_dca_aggressiveness.blank?
      self.adaptive_dca_floor_pct = ADAPTIVE_DCA_DEFAULT_FLOOR_PCT if adaptive_dca_floor_pct.blank?
      self.adaptive_dca_ceiling_pct = ADAPTIVE_DCA_DEFAULT_CEILING_PCT if adaptive_dca_ceiling_pct.blank?
      # Seed EWMA immediately with 24h market data so the UI shows
      # the belief price right away instead of "Calibrating..."
      seed_adaptive_ewma_from_market!
    else
      clear_adaptive_ewma_state!
    end
  end

  def adaptive_dca_enabled_was
    settings_was&.dig('adaptive_dca_enabled')
  end
end
