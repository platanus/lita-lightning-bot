require "json"
module Lita
  module Services
    class LndAdapter
      include HTTParty
      base_uri 'http://localhost:3000/api/v1'

      def get_users
        self.class.get("/users")
      end

      def create_user
        NotImplementedError
      end

      def get_user_balance(user)
        NotImplementedError
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

      def pay_invoice(user, pay_req)
        self.class.post('/pay_invoice',
                        :body => {  :user => user,
                                    :pay_req => pay_req
                        }.to_json,
                        :headers => { 'Content-Type' => 'application/json' })
      end

      def get_wallet_balance
        self.class.get("/wallet_balance")
      end

      def create_invoice(user, amount)
        self.class.post('/create_invoice',
            :body => {  :user => user,
                        :amount => amount.to_s
                      }.to_json,
                      :headers => { 'Content-Type' => 'application/json' })
      end

    end
  end
end