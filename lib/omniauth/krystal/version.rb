# frozen_string_literal: true

module OmniAuth
  module Krystal

    VERSION_FILE = File.expand_path('../../../VERSION', __dir__)
    if File.file?(VERSION_FILE)
      VERSION = File.read(VERSION_FILE).strip
    else
      VERSION = '0.0.0'
    end
  end
end
