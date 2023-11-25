# frozen_string_literal: true

require 'faraday'
require 'retriable'
require 'json'

require_relative 'events/version'
require_relative 'client'
require_relative 'request'

module Webex
  module Events
    class Error < StandardError; end

    class Config
      class << self
        attr_accessor :access_token

        def configure(&bloc)
          bloc.yield self
        end
      end
    end
  end
end
