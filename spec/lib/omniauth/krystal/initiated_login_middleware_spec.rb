# frozen_string_literal: true

require 'spec_helper'

module OmniAuth
  module Krystal
    RSpec.describe InitiatedLoginMiddleware do
      # A signing key which can be used for the purposes of creating fake
      # JWTs for this test.
      let(:raw_signing_key) do
        <<~KEY
          -----BEGIN EC PRIVATE KEY-----
          MHcCAQEEIIKVuMVd4G3FZ5hkh9L9H9O2e3UlTZaX+zCCeLwRrH2+oAoGCCqGSM49
          AwEHoUQDQgAEoRCJVcbJAMnc9FoVl/rsudirB7ieufz6nTMg2hpRpEuW5XtEbXu6
          PUJGQM6uJPjbB0JECenCGMy2MGxZofblmw==
          -----END EC PRIVATE KEY-----
        KEY
      end
      let(:signing_key) { OpenSSL::PKey::EC.new(raw_signing_key) }

      # The application which will be called by the middleware.
      let(:app_call_result) { [200, {}, ['Hello world!']] }
      let(:app) do
        app = double('App')
        allow(app).to receive(:call).and_return(app_call_result)
        app
      end

      # Attributes provided to the middleware.
      let(:provider_name) { 'krystal' }
      let(:anti_replay_expiry_seconds) { 60 }

      # Mock up a redis client to use for testing.
      let(:redis) { nil }

      # Mock up a keys instance which can be used to resolve the appropriate
      # key for the given state attribute.
      let(:keys) do
        key = JWT::JWK.new(signing_key, {
                             kid: 'identity-signing',
                             use: 'sig',
                             alg: 'ES256'
                           })
        keys = double('Keys')
        allow(keys).to receive(:call).and_return(JWT::JWK::Set.new(key))
        keys
      end

      # The attributes to provide in the state attribute
      let(:anti_replay_token) { SecureRandom.hex(16) }
      let(:expiry) { Time.now.to_i + 10 }

      # Attibutes for the actual request made to the middleware.
      let(:request_method) { 'GET' }
      let(:request_path) { "/auth/#{provider_name}/callback" }
      let(:request_params) { { 'state' => state_param } }
      let(:state_param) do
        jwt = JWT.encode(jwt_payload, signing_key, 'ES256', { kid: 'identity-signing' })
        "kidil_#{jwt}"
      end
      let(:jwt_payload) { { ar: anti_replay_token, exp: expiry } }
      let(:session) { {} }
      let(:env) do
        {
          'PATH_INFO' => request_path,
          'REQUEST_METHOD' => request_method,
          'QUERY_STRING' => URI.encode_www_form(state: state_param),
          'rack.session' => session
        }
      end

      # The instance of the middleware
      let(:instance) { described_class.new(app, redis: redis) }

      before do
        allow(SigningKeys).to receive(:new).and_return(keys)
      end

      describe '#call' do
        context 'when the path does not match' do
          let(:request_path) { '/blah' }

          it 'calls the application' do
            expect(instance.call(env)).to eq app_call_result
          end

          it 'does not set the session state' do
            instance.call(env)
            expect(session).to be_empty
          end
        end

        context 'when there is no state parameter' do
          let(:state_param) { nil }

          it 'calls the application' do
            expect(instance.call(env)).to eq app_call_result
          end

          it 'does not set the session state' do
            instance.call(env)
            expect(session).to be_empty
          end
        end

        context 'when the state parameter does not begin with kidil_' do
          let(:state_param) { 'blahblah' }

          it 'calls the application' do
            expect(instance.call(env)).to eq app_call_result
          end

          it 'does not set the session state' do
            instance.call(env)
            expect(session).to be_empty
          end
        end

        context 'when the state parameter is not a valid JWT' do
          let(:state_param) { 'kidil_blahblahblah' }

          it 'raises an error' do
            expect { instance.call(env) }.to raise_error InitiatedLoginMiddleware::JWTDecodeError
          end
        end

        context 'when the state parameter is is valid but has expired' do
          let(:expiry) { Time.now.to_i - 10 }

          it 'raises an error' do
            expect { instance.call(env) }.to raise_error InitiatedLoginMiddleware::JWTExpiredError
          end
        end

        context 'when the state parameter is valid' do
          it 'calls the application' do
            expect(instance.call(env)).to eq app_call_result
          end

          it 'sets a session to the state parameter' do
            instance.call(env)
            expect(session['omniauth.state']).to eq state_param
          end

          context 'when there are no additional claims in the jwt' do
            it 'sets the params parameter to an empty hash' do
              instance.call(env)
              expect(session['omniauth.params']).to eq({})
            end
          end

          context 'when there are some additional claims in the jwt' do
            let(:jwt_payload) { { ar: anti_replay_token, exp: expiry, user: 'b1952fb3-2bcc-46e7-a8d0-56a68f96301f' } }

            it 'sets the additional claims in the decoded jwt to a params parameter' do
              instance.call(env)
              expect(session['omniauth.params']).to eq({ 'user' => 'b1952fb3-2bcc-46e7-a8d0-56a68f96301f' })
            end
          end
        end

        context 'when redis is available' do
          let(:redis) do
            redis = double('Redis')
            redis
          end

          context 'when the replay token has been seen before' do
            before do
              allow(redis).to receive(:get).with("kidil-ar:#{anti_replay_token}").and_return(Time.now.to_i)
            end

            it 'raises an error' do
              expect { instance.call(env) }.to raise_error InitiatedLoginMiddleware::AntiReplayTokenAlreadyUsedError
            end
          end

          context 'when the replay token has not been seen before' do
            before do
              allow(redis).to receive(:get).and_return(nil)
              allow(redis).to receive(:set)
            end

            it 'sets the replay token in redis' do
              Timecop.freeze do
                instance.call(env)
                expect(redis).to have_received(:set).with("kidil-ar:#{anti_replay_token}",
                                                          Time.now.to_i,
                                                          nx: true,
                                                          ex: anti_replay_expiry_seconds)
              end
            end

            it 'calls the application' do
              expect(instance.call(env)).to eq app_call_result
            end

            it 'sets the value in the session' do
              instance.call(env)
              expect(session['omniauth.state']).to eq state_param
            end
          end
        end
      end
    end
  end
end
