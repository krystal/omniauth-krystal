# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

module OmniAuth
  module Krystal
    class SigningKeys
      attr_reader :cache, :cache_set_at

      def initialize(url)
        @url = url
        @cache = nil
      end

      def call(_options)
        invalidate_cache_if_appropriate
        return @cache if @cache

        download_jwks
        @cache_set_at = Time.now.to_i
        @cache
      end

      private

      # Invalidate the cache if it's been more than 5 minutes since we last
      # cached the data.
      def invalidate_cache_if_appropriate
        return if @cache_set_at && @cache_set_at >= (Time.now.to_i - 300)

        @cache = nil
      end

      # rubocop:disable Metrics/AbcSize
      def download_jwks
        uri = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        raise Error, "Failed to download signing keys from #{@url}" if response.code != '200'

        body = JSON.parse(response.body)

        @cache = JWT::JWK::Set.new(body)
        @cache.select! { |key| key[:use] == 'sig' }
        @cache
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
