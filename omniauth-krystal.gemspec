require File.expand_path('../lib/omniauth/krystal/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "omniauth-krystal"
  s.description   = %q{OmniAuth strategy for Krystal Identity}
  s.summary       = s.description
  s.homepage      = "https://github.com/krystal/omniauth-krystal"
  s.version       = OmniAuth::Krystal::VERSION

  s.files         = Dir.glob("{lib}/**/*")
  s.require_paths = ["lib"]

  s.add_dependency 'omniauth', '~> 2.0'
  s.add_dependency 'omniauth-oauth2', '~> 1.8'
  
  s.authors       = ["Adam Cooke"]
  s.email         = ["adam@krystal.uk"]

  s.license       = 'MIT'
end
