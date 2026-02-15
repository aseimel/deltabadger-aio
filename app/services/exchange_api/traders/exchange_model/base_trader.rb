module ExchangeApi
  module Traders
    module ExchangeModel
      class BaseTrader < ExchangeApi::Traders::BaseTrader
        def initialize(exchange:, api_key:)
          @exchange = exchange
          @api_key_record = api_key
          @exchange.set_client(api_key: api_key)
        end

        def fetch_order_by_id(order_id, *_args)
          result = @exchange.get_order(order_id: order_id)
          return result if result.failure?

          data = result.data
          Result::Success.new(
            external_id: order_id,
            amount: data[:amount_exec],
            price: data[:price]
          )
        end

        def currency_balance(currency, _bot_id = nil)
          asset = find_asset_by_symbol(currency)
          return Result::Failure.new("Asset #{currency} not found on #{@exchange.name}") unless asset

          result = @exchange.get_balance(asset_id: asset.id)
          return result if result.failure?

          Result::Success.new(result.data[:free])
        end

        protected

        def find_ticker(base, quote)
          @exchange.tickers.available.find_by(base: base, quote: quote)
        end

        def find_asset_by_symbol(symbol)
          @exchange.tickers.available.includes(:base_asset, :quote_asset).each do |t|
            return t.base_asset if t.base == symbol
            return t.quote_asset if t.quote == symbol
          end
          nil
        end
      end
    end
  end
end
