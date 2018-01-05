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

      def success_payment?(payment_request_response)
        payment_request_response["status"] == "true"
      end

      def has_errors_in_create_user?(create_user_response)
        create_user_response["error"] != ""
      end

      # Routes.
      route(/muestrame los usuarios/i, command: true) do |response|
        users = lnd_service.get_users
        response.reply(t(:get_users, subject: users))
      end

      route(/cual es mi (saldo|balance)?/i, command: true, help: help_msg(:get_user_balance)) do |response|
        user_balance = lnd_service.get_user_balance(response.user.id)["user"]
        response.reply(t(:get_user_balance, user_balance: user_balance["balance"]))
      end

      route(/cual es el saldo total?/i, command: true, help: help_msg(:get_wallet_balance)) do |response|
        wallet_balance = lnd_service.get_wallet_balance["wallet_balance"]
        confirmed_balance = wallet_balance["confirmed_balance"]
        unconfirmed_balance = wallet_balance["unconfirmed_balance"]
        total_balance = wallet_balance["total_balance"]
        response.reply(t(:get_wallet_balance, confirmed_balance: confirmed_balance, unconfirmed_balance: unconfirmed_balance, total_balance: total_balance))
      end

      route(/(generar|crear) (cobro|invoice) por (\d+)/i, command: true, help: help_msg(:create_invoice)) do |response|
        user = response.user.id
        amount = response.matches[0][2]
        create_invoice_response = lnd_service.create_invoice(user, amount)
        if success_payment?(create_invoice_response)
          response.reply(t(:create_invoice, pay_req: create_invoice_response["pay_req"]))
        else
          response.reply(t(:error, error: create_invoice_response["pay_req"]))
        end

      end

      route(/paga la cuenta ([^\s]+)/i, command: true, help: help_msg(:pay_invoice)) do |response|
        user = response.user.id
        pay_req = response.matches[0][0]
        payment_request_response = lnd_service.pay_invoice(user, pay_req)["pay_req"]
        if success_payment?(payment_request_response)
          response.reply(t(:pay_invoice))
        else
          response.reply(t(:pay_invoice_error, error: payment_request_response["payment_error"]))
        end
      end

      route(/(generar|crear) usuario ([^\s]+)/i, command: true, help: help_msg(:create_user)) do |response|
        user = response.user.id
        email = response.matches[0][1]
        create_user_response = lnd_service.create_user(user, email)["user"]
        if has_errors_in_create_user?(create_user_response)
          response.reply(t(:create_user_error, error: create_user_response["error"]))
        else
          response.reply(t(:create_user, email: create_user_response["email"]))
        end
      end

      route(/(ver|mirar) (invoice|cuenta) ([^\s]+)/i, command: true, help: help_msg(:decrypt_invoice)) do |response|
        invoice = response.matches[0][2]
        decrypt_invoice_response = lnd_service.decrypt_invoice(invoice)["pay_req"]
        value = decrypt_invoice_response["num_satoshis"]
        destination = decrypt_invoice_response["destination"]
        description = decrypt_invoice_response["description"]
        response.reply(t(:decrypt_invoice, value: value, destination: destination, description: description))
      end

      route(/cual es el estado (del|de la) (invoice|cuenta) ([^\s]+)/i, command: true, help: help_msg(:lookup_invoice)) do |response|
        invoice = response.matches[0][2]
        lookup_invoice_response = lnd_service.lookup_invoice(invoice)["pay_req"]
        status = lookup_invoice_response["status"]
        if status == 'true'
          status = 'pagada'
        elsif status == 'false'
          status = 'no pagada'
        end
        response.reply(t(:lookup_invoice, status: status))
      end

      http.post "/notify_payment" do |request|
        data = MultiJson.load(request.body, symbolize_keys: true)
        user = User.find_by_id(data[:user])
        satoshis = data[:satoshis]
        robot.send_message(Source.new(user: user), t(:notify_payment, amount: satoshis))
      end

      Lita.register_handler(self)
    end
  end
end
