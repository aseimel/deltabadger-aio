module ExchangeApi
  module Traders
    module ExchangeModel
      class LimitTrader < BaseTrader
        def buy(base:, quote:, price:, percentage:, force_smart_intervals:, smart_intervals_value:)
          ticker = find_ticker(base, quote)
          return Result::Failure.new("Ticker #{base}-#{quote} not found on #{@exchange.name}") unless ticker

          ask_result = @exchange.get_ask_price(ticker: ticker)
          return ask_result if ask_result.failure?

          limit_price = calculate_limit_price(ticker, ask_result.data, -percentage)
          amount = determine_base_amount(ticker, price, limit_price, force_smart_intervals, smart_intervals_value)

          result = @exchange.limit_buy(ticker: ticker, amount: amount, amount_type: :base, price: limit_price)
          return result if result.failure?

          Result::Success.new(external_id: result.data[:order_id])
        end

        def sell(base:, quote:, price:, percentage:, force_smart_intervals:, smart_intervals_value:, is_legacy:)
          ticker = find_ticker(base, quote)
          return Result::Failure.new("Ticker #{base}-#{quote} not found on #{@exchange.name}") unless ticker

          bid_result = @exchange.get_bid_price(ticker: ticker)
          return bid_result if bid_result.failure?

          limit_price = calculate_limit_price(ticker, bid_result.data, percentage)
          amount = determine_base_amount(ticker, price, limit_price, force_smart_intervals, smart_intervals_value)

          result = @exchange.limit_sell(ticker: ticker, amount: amount, amount_type: :base, price: limit_price)
          return result if result.failure?

          Result::Success.new(external_id: result.data[:order_id])
        end

        private

        def calculate_limit_price(ticker, current_price, percentage)
          adjusted = current_price * (1 + percentage / 100.0)
          ticker.adjusted_price(price: adjusted)
        end

        def determine_base_amount(ticker, quote_amount, limit_price, force_smart_intervals, smart_intervals_value)
          if force_smart_intervals && smart_intervals_value.present?
            base_amount = smart_intervals_value.to_d / limit_price
          else
            base_amount = quote_amount.to_d / limit_price
          end

          min = ticker.minimum_base_size || 0
          [base_amount, min].max
        end
      end
    end
  end
end
