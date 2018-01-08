require "json"
module Lita
  module Services
    class LndAdapter
      include HTTParty
      base_uri 'http://localhost:3000/api/v1'

      def headers
        {"Authorization" => "Token token=\"#{ENV['LND_API_TOKEN']}\"", 'Content-Type' => 'application/json' }
      end

      def create_invoice(user, amount)
        self.class.post('/payments/create_invoice',
                        :body => {  :user => user,
                                    :amount => amount.to_s
                        }.to_json,
                        :headers => headers)
      end

      def create_user(user, email)
        self.class.post('/users/create',
                        :body => {  :slack_id => user,
                                    :email => email,
                        }.to_json,
                        :headers => headers)
      end

      def decrypt_invoice(invoice)
        self.class.get('/service/decrypt_invoice/' + invoice, headers: headers)
      end

      def force_refresh(user)
        self.class.get('/payments/force_refresh/' + user, headers: headers)
      end

      def get_users
        self.class.get('/users', headers: headers)
      end

      def get_wallet_balance
        self.class.get('/wallet/balance', headers: headers)
      end

      def get_user_balance(user)
        self.class.get('/users/' + user + '/balance/', headers: headers)
      end

      def get_open_channels
        NotImplementedError
      end

      def get_peers
        NotImplementedError
      end

      def get_peer_list
        NotImplementedError
      end

      def lookup_invoice(invoice)
        self.class.get('/service/lookup_invoice/' + invoice, headers: headers)
      end

      def pay_invoice(user, pay_req)
        self.class.post('/payments/pay_invoice',
                        :body => {  :user => user,
                                    :pay_req => pay_req
                        }.to_json,
                        :headers =>  headers)
      end
    end
  end
end