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
  it { is_expected.to route("@lita paga la cuenta lntb50u1pdyhmnfpp5qgwmqsexh6t3mpysl3yxhvsh6hdmpvy2zx5ksn7xh0fmhqkxw3aqdq025uyxse58qunwsgcqzysexn9a56c2c6sayyqyqfffrn2yfjwxyd3kfqrktkj47632uua2f9zrl085p8ul79lvvryu2a5ql9p4686mulpz2s56f63gkw7wwv2rhqp6cje2r") }
  it { is_expected.to route("@lita generar usuario cristobal.griffero@platan.us") }

end
