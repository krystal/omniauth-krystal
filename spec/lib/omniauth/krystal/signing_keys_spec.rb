# frozen_string_literal: true

require 'spec_helper'

module OmniAuth
  module Krystal
    RSpec.describe SigningKeys do
      let(:url) { 'https://identity.krystal.io/.well-known/signing.json' }
      let(:cache) { nil }
      let(:cache_set_at) { nil }
      let(:request_body) do
        '{"keys":[{"kty":"EC","crv":"P-256","x":"AwSV14oAE35bfUUvxcMOVYr63PfrZKWbu-wFCYKvhT0",' \
          '"y":"LQqIzJMYhcft3jYUvJyAOd7-qK5X7ggsVE0lorXm0lE","kid":"identity-signing","use":"sig",' \
          '"alg":"ES256"}]}'
      end
      let(:request_status) { 200 }
      let(:instance) { described_class.new(url) }

      before do
        stub_request(:get, url).to_return(status: request_status, body: request_body)

        instance.instance_variable_set('@cache', cache) if cache
        instance.instance_variable_set('@cache_set_at', cache_set_at) if cache_set_at
      end

      describe '#call' do
        subject(:result) { instance.call({}) }

        context 'when requests to the backend are successful' do
          context 'when the cache was never set' do
            it 'returns the new set of keys' do
              expect(result).to be_a JWT::JWK::Set
            end

            it 'made a request' do
              result
              expect(WebMock).to have_requested(:get, url)
            end

            it 'sets the cache time to now' do
              Timecop.freeze do
                result
                expect(instance.cache_set_at).to eq Time.now.to_i
              end
            end
          end

          context 'when the cache was last set more than 5 minutes ago' do
            let(:cache) { JWT::JWK::Set.new }
            let(:cache_set_at) { Time.now.to_i - 600 }

            it 'clears the cache' do
              Timecop.freeze do
                result
                expect(instance.cache_set_at).to eq Time.now.to_i
              end
            end

            it 'downloads the latest keys' do
              result
              expect(WebMock).to have_requested(:get, url)
            end

            it 'returns the new set of keys' do
              expect(result).to be_a JWT::JWK::Set
              identity_key = result.keys.find { |r| r.kid == 'identity-signing' }
              expect(identity_key).to be_a JWT::JWK::EC
            end
          end

          context 'when the cache was last set less than 5 minutes ago' do
            let(:cache) { JWT::JWK::Set.new }
            let(:cache_set_at) { Time.now.to_i - 60 }

            it 'returns the cached data' do
              expect(result).to eq cache
              expect(WebMock).to_not have_requested(:get, url)
            end
          end
        end
      end
    end
  end
end
