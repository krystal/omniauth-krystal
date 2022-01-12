# frozen_string_literal: true

require File.expand_path('lib/omniauth/krystal/version', __dir__)

Gem::Specification.new do |s|
  s.name          = 'omniauth-krystal'
  s.description   = 'OmniAuth strategy for Krystal Identity'
  s.summary       = s.description
  s.homepage      = 'https://github.com/krystal/omniauth-krystal'
  s.version       = OmniAuth::Krystal::VERSION
  s.required_ruby_version = '>= 2.6'

  s.files         = Dir.glob('{lib}/**/*')
  s.require_paths = ['lib']

  s.add_dependency 'omniauth', '~> 2.0'
  s.add_dependency 'omniauth-oauth2', '~> 1.7'

  s.authors       = ['Adam Cooke']
  s.email         = ['adam@krystal.uk']

  s.license       = 'MIT'
  s.metadata['rubygems_mfa_required'] = 'true'
end
