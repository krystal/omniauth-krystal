# frozen_string_literal: true

require 'jwt'
require 'omniauth/krystal/signing_keys'

module OmniAuth
  module Krystal
    class InitiatedLoginMiddleware
      class Error < StandardError
      end

      class JWTDecodeError < Error
      end

      class JWTExpiredError < Error
      end

      class AntiReplayTokenAlreadyUsedError < Error
      end

      JWT_RESERVED_CLAIMS = %w[ar exp nbf iss aud jti iat sub].freeze

      def initialize(app, options = {})
        @app = app
        @options = options

        @options[:provider_name] ||= 'krystal'
        @options[:identity_url] ||= ENV.fetch('KRYSTAL_IDENTITY_URL', 'https://identity.krystal.io')
        @options[:anti_replay_expiry_seconds] ||= 60

        @keys = SigningKeys.new("#{@options[:identity_url]}/.well-known/signing.json")
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def call(env)
        unless env['PATH_INFO'] == "/auth/#{@options[:provider_name]}/callback"
          # If it's not a Krystal Identity auth callback then we don't
          # need to do anything here.
          return @app.call(env)
        end

        request = Rack::Request.new(env)
        state = request.params['state']

        if state.nil? || !state.start_with?('kidil_')
          # Return to the app if the state is not a Krystal Identity
          # initiated login.
          return @app.call(env)
        end

        # Decode the JWT and ensure that the state is valid. JWT will check
        # the expiry.
        data = nil
        begin
          data, = JWT.decode(state.sub(/\Akidil_/, ''), nil, true, { algorithm: 'ES256', jwks: @keys })
        rescue JWT::ExpiredSignature
          raise JWTExpiredError, 'State parameter has expired'
        rescue JWT::DecodeError
          raise JWTDecodeError,
                'Invalid state parameter provided (either malformed, expired or signed with the wrong key)'
        end

        # Verify the replay token
        verify_anti_replay_token(data['ar'])

        # Set the expected omniauth state to the state that we have been given so it
        # thinks the session is trusted as normal.
        env['rack.session']['omniauth.state'] = state

        # Set any additional params that were passed in the state.
        env['rack.session']['omniauth.params'] = data.reject { |key| JWT_RESERVED_CLAIMS.include?(key) }

        @app.call(env)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      private

      def verify_anti_replay_token(token)
        return if @options[:redis].nil?

        redis = @options[:redis]
        key = "kidil-ar:#{token}"
        if redis.get(key)
          raise AntiReplayTokenAlreadyUsedError, 'Anti replay token has already been used'
        end

        redis.set(key,
                  Time.now.to_i,
                  nx: true, ex: @options[:anti_replay_expiry_seconds])
      end
    end
  end
end
