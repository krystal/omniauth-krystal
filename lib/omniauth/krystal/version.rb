# frozen_string_literal: true

module OmniAuth
  module Krystal
    VERSION_FILE = File.expand_path('../../../VERSION', __dir__)
    VERSION = if File.file?(VERSION_FILE)
                File.read(VERSION_FILE).strip
              else
                '0.0.0'
              end
  end
end
