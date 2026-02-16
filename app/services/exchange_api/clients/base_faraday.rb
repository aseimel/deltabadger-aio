module ExchangeApi
  module Clients
    module BaseFaraday
      def base_client(url_base)
        Faraday.new(
          url: url_base,
          proxy: ENV['US_HTTPS_PROXY']
        ) do |conn|
          conn.options.open_timeout = 10
          conn.options.timeout = 15
          conn.adapter Faraday.default_adapter
        end
      end

      def caching_client(url_base, expire_time = ENV['DEFAULT_MARKET_CACHING_TIME'])
        Faraday.new(
          url: url_base,
          proxy: ENV['US_HTTPS_PROXY']
        ) do |builder|
          builder.options.open_timeout = 10
          builder.options.timeout = 15
          builder.use :manual_cache,
                      expires_in: expire_time
          builder.adapter Faraday.default_adapter
        end
      end
    end
  end
end
