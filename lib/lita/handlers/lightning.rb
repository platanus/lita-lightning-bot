require 'json'
module Lita
  module Handlers
    class Lightning < Handler

      def self.help_msg(route)
        { "lightning-payments: #{t("help.#{route}.usage")}" => t("help.#{route}.description") }
      end

      def lnd_service
        Services::LndAdapter.new
      end

      def get_user_balance(user)
        lnd_service.get_user_balance(user)
      end

      def get_wallet_balance
        lnd_service.get_wallet_balance
      end

      def get_users
        lnd_service.get_users
      end

      def create_invoice(user, amount)
        lnd_service.create_invoice(user, amount)
      end

      def pay_payment_request(user, pay_req)
        lnd_service.pay_invoice(user, pay_req)
      end

      def has_errors_in_payment?(payment_request_response)
        payment_request_response["payment_error"] != ""
      end

      def has_errors_in_create_user?(create_user_response)
        create_user_response["error"] != ""
      end

      def create_user(user, email)
        lnd_service.create_user(user, email)
      end

      # Routes.

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

      route(/(generar|crear) (cobro|invoice) por (\d+)/i, command: true, help: help_msg(:create_invoice)) do |response|
        user = response.user.id
        amount = response.matches[0][2]
        pay_req = create_invoice(user, amount)["pay_req"]
        response.reply(t(:create_invoice, pay_req: pay_req))
      end

      route(/paga la cuenta ([^\s]+)/i, command: true, help: help_msg(:pay_invoice)) do |response|
        user = response.user.id
        pay_req = response.matches[0][0]
        payment_request_response = pay_payment_request(user, pay_req)["pay_req"]
        if has_errors_in_payment?(payment_request_response)
          response.reply(t(:pay_invoice_error, error: payment_request_response["payment_error"]))
        else
          response.reply(t(:pay_invoice))
        end
      end

      route(/(generar|crear) usuario ([^\s]+)/i, command: true, help: help_msg(:create_user)) do |response|
        user = response.user.id
        email = response.matches[0][1]
        create_user_response = create_user(user, email)["user"]
        if has_errors_in_create_user?(create_user_response)
          response.reply(t(:create_user_error, error: create_user_response["error"]))
        else
          response.reply(t(:create_user, email: create_user_response["email"]))
        end
      end

      route(/gracias/i, command: true, help: help_msg(:thanks)) do |response|
        response.reply(t(:yourwelcome, subject: response.user.mention_name))
      end

      Lita.register_handler(self)
    end
  end
end
