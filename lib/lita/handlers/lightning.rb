require 'json'
module Lita
  module Handlers
    class Lightning < Handler

      def self.help_msg(route)
        { "lightning-payments: #{t("help.#{route}.usage")}" => t("help.#{route}.description") }
      end

      def get_user_balance(user)
        user_service = Services::LndAdapter.new
        user_service.get_user_balance(user)
      end

      def get_wallet_balance
        user_service = Services::LndAdapter.new
        user_service.get_wallet_balance
      end

      def get_users
        user_service = Services::LndAdapter.new
        user_service.get_users
      end

      def create_invoice(user, amount)
        user_service = Services::LndAdapter.new
        user_service.create_invoice(user, amount)
      end

      def pay_payment_request(user, pay_req)
        user_service = Services::LndAdapter.new
        user_service.pay_invoice(user, pay_req)
      end

      # Routes.

      route(/crear usuario/i, command: true) do |response|
        user_service = Services::LndAdapter.new
        user_service.create_user
        response.reply(t(:yourwelcome, subject: response.user.mention_name))
      end

      route(/muestrame los usuarios/i, command: true) do |response|
        users = get_users
        response.reply(t(:get_users, subject: users))
      end

      route(/cual es mi saldo?/i, command: true, help: help_msg(:get_user_balance)) do |response|
        user_balance = get_user_balance(response.user.id)
        response.reply(t(:get_user_balance, subject: user_balance))
      end

      route(/cual es el saldo total?/i, command: true, help: help_msg(:get_wallet_balance)) do |response|
        wallet_balance = get_wallet_balance["wallet_balance"]
        confirmed_balance = wallet_balance["confirmed_balance"]
        unconfirmed_balance = wallet_balance["unconfirmed_balance"]
        total_balance = wallet_balance["total_balance"]
        response.reply(t(:get_wallet_balance, confirmed_balance: confirmed_balance, unconfirmed_balance: unconfirmed_balance, total_balance: total_balance))
      end

      route(/generar cobro por (\d+)/i, command: true, help: help_msg(:create_invoice)) do |response|
        user = response.user.id
        amount = response.matches[0][0]
        pay_req = create_invoice(user, amount)["pay_req"]
        response.reply(t(:create_invoice, pay_req: pay_req))
      end

      route(/paga la cuenta ([^\s]+)/i, command: true, help: help_msg(:pay_invoice)) do |response|
        user = response.user.id
        pay_req = response.matches[0][0]
        payment_request_response = pay_payment_request(user, pay_req)
        response.reply(t(:create_invoice, payment_request_response: payment_request_response))
      end

      route(/gracias/i, command: true, help: help_msg(:thanks)) do |response|
        response.reply(t(:yourwelcome, subject: response.user.mention_name))
      end

      Lita.register_handler(self)
    end
  end
end
