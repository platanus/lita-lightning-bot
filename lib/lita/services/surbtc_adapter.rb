require "httparty"
module Lita
  module Services
    class SurbtcAdapter
      def get_current_price
        response = HTTParty.get('https://www.surbtc.com/api/v2/markets/btc-clp/ticker')
        parsed = JSON.parse response, symbolize_names: true
        parsed[:ticker][:last_price][0]
      end
    end
  end
end