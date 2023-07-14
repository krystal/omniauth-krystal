# frozen_string_literal: true

require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Krystal < OmniAuth::Strategies::OAuth2
      option :name, 'krystal'

      option :client_options,
             url: ENV.fetch('KRYSTAL_IDENTITY_URL', 'https://identity.krystal.io'),
             site: ENV.fetch('KRYSTAL_IDENTITY_API_URL', nil),
             authorize_url: ENV.fetch('KRYSTAL_IDENTITY_OAUTH_AUTHORIZE_URL', nil),
             token_url: ENV.fetch('KRYSTAL_IDENTITY_OAUTH_TOKEN_URL', nil)

      option :authorize_params,
             scope: 'user.profile'

      uid { raw_info['user']['id'] }

      info do
        {
          name: "#{raw_info['user']['first_name']} #{raw_info['user']['last_name']}",
          email: raw_info['user']['email_address']
        }
      end

      extra do
        {
          raw_info: raw_info,
          scope: scope,
          session_id: raw_info['session_id'],
          first_name: raw_info['user']['first_name'],
          last_name: raw_info['user']['last_name'],
          email_addresses: raw_info['user']['email_addresses'],
          roles: raw_info['user']['roles'],
          two_factor_auth_enabled: raw_info['user']['two_factor_auth_enabled']
        }
      end

      # rubocop:disable Metrics/AbcSize
      def initialize(app, *args, &block)
        super

        options.client_options.site ||= "#{options.client_options.url}/api/v1"
        options.client_options.authorize_url ||= "#{options.client_options.url}/oauth2/auth"
        options.client_options.token_url ||= "#{options.client_options.url}/oauth2/token"
      end
      # rubocop:enable Metrics/AbcSize

      def scope
        access_token['scope']
      end

      def callback_url
        full_host + script_name + callback_path
      end

      def raw_info
        @raw_info ||= access_token.get('user').parsed
      end
    end
  end
end
