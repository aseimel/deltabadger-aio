require 'result'
require 'csv'

module ExchangeApi
  module WithdrawalInfo
    module Kraken
      class AccountInfoProcessor < BaseAccountInfoProcessor
        include ExchangeApi::Clients::Kraken

        def initialize(
          api_key:,
          api_secret:,
          map_errors: ExchangeApi::MapErrors::Kraken.new
        )
          @client = get_base_client(api_key, api_secret)
          @caching_client = get_caching_client(api_key, api_secret)
          @map_errors = map_errors
        end

        def withdrawal_minimum(currency)
          result = fetch_minimum_withdrawal_amount(currency)
          return result if result.failure?

          result
        end

        def withdrawal_currencies
          response = @caching_client.assets
          return error_to_failure(response.fetch('error')) if response.fetch('error').any?

          all_symbols = response['result'].map { |_symbol, data| data['altname'] }
          Result::Success.new(all_symbols)
        rescue StandardError => e
          Result::Failure.new('Could not fetch currencies from Kraken', RECOVERABLE.to_s)
        end

        def available_wallets
          response = @client.withdraw_addresses
          return error_to_failure(response.fetch('error')) if response.fetch('error').any?

          addresses = response.fetch('result').map do |addr|
            { currency: addr['asset'], address: addr['key'] }
          end
          Result::Success.new(addresses)
        rescue StandardError => e
          Result::Failure.new('Could not fetch withdrawal addresses from Kraken')
        end

        def available_funds(bot)
          minimum = withdrawal_minimum(bot.currency)
          return minimum unless minimum.success?

          response = @client.withdraw_info(asset: bot.currency, key: bot.address, amount: minimum.data)
          return error_to_failure(response.fetch('error')) if response.fetch('error').any?

          data = response.fetch('result').fetch('limit').to_f
          Result::Success.new(data)
        rescue StandardError => e
          Result::Failure.new('Could not fetch funds from Kraken', RECOVERABLE.to_s)
        end

        private

        def fetch_minimum_withdrawal_amount(currency)
          # @client.withdraw_addresses can filter by asset, and give the method but not the network
          # @client.withdraw_methods can filter by asset and network, and give the minimum
          # For this reason, we use the most restrictive minimum for a given asset, regardless of network
          response = @client.withdraw_methods(asset: currency)
          return error_to_failure(response.fetch('error')) if response.fetch('error').any?

          data = response.fetch('result').map { |method| method.fetch('minimum').to_f }.max
          if data.nil?
            Result::Failure.new('Could not fetch minimum withdrawal amount from Kraken')
          else
            Result::Success.new(data)
          end
        end
      end
    end
  end
end
