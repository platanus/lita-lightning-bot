require "lita"
require "httparty"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/lightning"
require "lita/services/lnd_adapter"
require "lita/services/surbtc_adapter"

Lita::Handlers::Lightning.template_root File.expand_path(
  File.join("..", "..", "templates"),
  __FILE__
)
