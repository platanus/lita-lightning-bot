require 'json'
module Lita
  module Handlers
    class Lightning < Handler
      BITCOIN_IN_SATOSHIS = 100000000

      def self.help_msg(route)
        { "lightning-payments: #{t("help.#{route}.usage")}" => t("help.#{route}.description") }
      end

      def lnd_service
        Services::LndAdapter.new
      end

      def success_payment?(payment_request_response)
        payment_request_response["error"].empty?
      end

      def success?(response)
        !response.key?(:errors)
      end

      def satoshis_to_clp(amount)
        surbtc_service = Services::SurbtcAdapter.new
        last_price = surbtc_service.get_current_price
        (Float(amount)/BITCOIN_IN_SATOSHIS)*Float(last_price)
      end

      def clp_to_satoshis(amount)
        surbtc_service = Services::SurbtcAdapter.new
        last_price = surbtc_service.get_current_price
        Integer(Integer(amount)/Float(last_price) * BITCOIN_IN_SATOSHIS)
      end

      def get_amount_of_satoshis(currency, amount)
        if ['CLP', 'clp'].include? currency
          clp_to_satoshis(amount)
        end
      end

      def clean_mention_name(mention_name)
        mention_name.delete('@') if mention_name
      end

      # Routes.
      route(/cual es mi (saldo|balance)/i,
        command: true, help: help_msg(:get_user_balance)) do |response|
        user_balance = lnd_service.get_user_balance(response.user.id)["user"]
        response.reply(t(:get_user_balance, user_balance: user_balance["balance"]))
      end

      route(/cual es el saldo total/i,
        command: true, help: help_msg(:get_wallet_balance)) do |response|
        wallet_balance = lnd_service.get_wallet_balance["wallet_balance"]
        confirmed_balance = wallet_balance["confirmed_balance"]
        unconfirmed_balance = wallet_balance["unconfirmed_balance"]
        total_balance = wallet_balance["total_balance"]
        response.reply(t(:get_wallet_balance,
          confirmed_balance: confirmed_balance,
          unconfirmed_balance: unconfirmed_balance,
          total_balance: total_balance))
      end

      route(/(genera|crea) (un )?(cobro|invoice) por (\d+)(\s)?([^\s]+)?/i,
        command: true, help: help_msg(:create_invoice)) do |response|
        user = response.user.id
        amount = response.matches[0][3]
        unless response.matches[0][5].nil?
          currency = response.matches[0][5]
          amount = get_amount_of_satoshis(currency, amount)
        end
        create_invoice_response = lnd_service.create_invoice(user, amount)
        if success?(create_invoice_response)
          qr_code = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=" +
            create_invoice_response["pay_req"]
          response.reply(t(:create_invoice,
            pay_req: create_invoice_response["pay_req"], qr_code: qr_code))
        else
          response.reply(t(:error, error: create_invoice_response["error"]["message"]))
        end
      end

      route(/co?ó?brale (\d+)(\s)?([^\s]+)? a ([^\s]+)/i,
            command: true, help: help_msg(:request_payment_to_user)) do |response|
        user = response.user.id
        amount = response.matches[0][0]
        destination_user = User.find_by_mention_name(clean_mention_name(response.matches[0][3]))
        create_invoice_response = lnd_service.create_invoice(user, amount)
        unless response.matches[0][2].nil?
          currency = response.matches[0][2]
          amount = get_amount_of_satoshis(currency, amount)
        end
        if success?(create_invoice_response)
          pay_req = create_invoice_response["pay_req"]
          qr_code = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=" +
              pay_req
          robot.send_message(Source.new(user: destination_user),
                             t(:request_payment_to_user, user: response.user.name,
                               amount: amount, pay_req: pay_req, qr_code: qr_code,
                               amount_in_clp: satoshis_to_clp(amount)))
          response.reply(t(:request_payment_to_user_confirmation, amount: amount, pay_req: pay_req, destination_user: destination_user.mention_name))
        else
          response.reply(t(:error, error: create_invoice_response["error"]["message"]))
        end
      end

      route(/paga la cuenta ([^\s]+)/i, command: true, help: help_msg(:pay_invoice)) do |response|
        user = response.user.id
        pay_req = response.matches[0][0]
        payment_response = lnd_service.pay_invoice(user, pay_req)
        balance = payment_response["balance"]
        fee = payment_response["fee"]
        if success_payment?(payment_response)
          response.reply(t(:pay_invoice, balance: balance, fee: fee))
        else
          response.reply(t(:pay_invoice_error, error: payment_response["error"]))
        end
      end

      route(/(ve|mira) el (invoice|cuenta) ([^\s]+)/i,
        command: true, help: help_msg(:decrypt_invoice)) do |response|
        invoice = response.matches[0][2]
        decrypt_invoice_response = lnd_service.decrypt_invoice(invoice)["pay_req"]
        value = decrypt_invoice_response["num_satoshis"]
        destination = decrypt_invoice_response["destination"]
        description = decrypt_invoice_response["description"]
        response.reply(t(:decrypt_invoice,
          value: value, destination: destination, description: description))
      end

      route(/cual es el estado (del|de la) (invoice|cuenta) ([^\s]+)/i,
        command: true, help: help_msg(:lookup_invoice)) do |response|
        invoice = response.matches[0][2]
        lookup_invoice_response = lnd_service.lookup_invoice(invoice)["pay_req"]
        status = lookup_invoice_response["status"]
        if status == 'true'
          status = t(:paid)
        elsif status == 'false'
          status = t(:not_paid)
        end
        response.reply(t(:lookup_invoice, status: status))
      end

      route(/(actualiza) (mis )?(invoices|cuentas|saldos)/i,
        command: true, help: help_msg(:force_refresh)) do |response|
        user = response.user.id
        lnd_service.force_refresh(user)
        response.reply(t(:force_refresh))
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
