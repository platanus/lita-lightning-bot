Gem::Specification.new do |spec|
  spec.name          = "lita-lightning"
  spec.version       = "0.1.0"
  spec.authors       = ["Cristobal Griffero"]
  spec.email         = ["cristobal.griffero@platan.us"]
  spec.description   = "Enables Lightning payment"
  spec.summary       = "Enables Lightning payment through slack"
  spec.homepage      = "TODO: Add a homepage"
  spec.license       = "TODO: Add a license"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"
  spec.add_runtime_dependency "httparty"
  spec.add_runtime_dependency "faraday", "~> 0.9"
  spec.add_runtime_dependency "faraday_middleware", "~> 0.9"
  spec.add_runtime_dependency "faraday-conductivity", "~> 0.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
