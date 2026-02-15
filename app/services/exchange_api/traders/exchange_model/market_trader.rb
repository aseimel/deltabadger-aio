module ExchangeApi
  module Traders
    module ExchangeModel
      class MarketTrader < BaseTrader
        def buy(base:, quote:, price:, force_smart_intervals:, smart_intervals_value:)
          ticker = find_ticker(base, quote)
          return Result::Failure.new("Ticker #{base}-#{quote} not found on #{@exchange.name}") unless ticker

          amount = determine_amount(ticker, price, force_smart_intervals, smart_intervals_value, :quote)
          result = @exchange.market_buy(ticker: ticker, amount: amount, amount_type: :quote)
          return result if result.failure?

          Result::Success.new(external_id: result.data[:order_id])
        end

        def sell(base:, quote:, price:, force_smart_intervals:, smart_intervals_value:, is_legacy:)
          ticker = find_ticker(base, quote)
          return Result::Failure.new("Ticker #{base}-#{quote} not found on #{@exchange.name}") unless ticker

          amount_type = is_legacy ? :base : :quote
          amount = determine_amount(ticker, price, force_smart_intervals, smart_intervals_value, amount_type)
          result = @exchange.market_sell(ticker: ticker, amount: amount, amount_type: amount_type)
          return result if result.failure?

          Result::Success.new(external_id: result.data[:order_id])
        end

        private

        def determine_amount(ticker, price, force_smart_intervals, smart_intervals_value, amount_type)
          if force_smart_intervals && smart_intervals_value.present?
            min = minimum_for(ticker, amount_type)
            [smart_intervals_value.to_d, min].max
          else
            min = minimum_for(ticker, amount_type)
            [price.to_d, min].max
          end
        end

        def minimum_for(ticker, amount_type)
          amount_type == :quote ? (ticker.minimum_quote_size || 0) : (ticker.minimum_base_size || 0)
        end
      end
    end
  end
end
