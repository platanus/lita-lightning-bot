require "spec_helper"

describe Lita::Handlers::Lightning, lita_handler: true do
  it "responds to user create invoice" do
    user = Lita::User.create(123, name: "test_bot")
    send_message("@lita generar cobro por 1000", as: user)
    expect(replies.last).to match("Para recibir tu pago debes enviar el siguiente request:")
  end

  it { is_expected.to route("@lita muestrame los usuarios") }
  it { is_expected.to route("@lita cual es mi saldo?") }
  it { is_expected.to route("@lita generar cobro por 50000") }
  it { is_expected.to route("@lita crear invoice por 50000") }
  it { is_expected.to route("@lita paga la cuenta lntb50u1pdyhmnfpp5qgwmqs") }
  it { is_expected.to route("@lita generar usuario cristobal.griffero@platan.us") }
end
