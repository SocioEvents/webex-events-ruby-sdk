# frozen_string_literal: true

require 'faraday'
require 'retriable'
require 'json'

require_relative 'events/version'
require_relative 'error'
require_relative 'response'
require_relative 'request'
require_relative 'client'

module Webex
  module Events
    class Config
      class << self
        attr_accessor :access_token

        def configure(&bloc)
          bloc.yield self
        end
      end
    end

    def self.ruby_version
      case RUBY_ENGINE
      when 'ruby'
        "ruby-#{RUBY_VERSION}"
      when 'jruby'
        "jruby-#{JRUBY_VERSION}"
      else
        RUBY_DESCRIPTION
      end
    end
  end
end
