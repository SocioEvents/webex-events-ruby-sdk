# frozen_string_literal: true

require 'faraday'
require 'retriable'
require 'json'
require 'securerandom'

require_relative 'events/version'
require_relative 'errors/error'
require_relative 'response'
require_relative 'request'
require_relative 'client'
require_relative 'rate_limiter'

module Webex
  module Events
    class Config
      class << self
        attr_accessor :access_token

        def configure(&bloc)
          bloc.yield self
        end

        def timeout
          @timeout ||= 30
        end

        def timeout=(timeout)
          if Integer(timeout) <= 0
            raise 'timeout must be greater than 0, %s is given' % timeout
          end
          @timeout = timeout
        end

        def open_timeout
          @open_timeout ||= 10
        end

        def open_timeout=(timeout)
          if Integer(timeout) <= 0
            raise 'open_timeout must be greater than 0, %s is given' % timeout
          end
          @open_timeout = timeout
        end

        def write_timeout
          @write_timeout ||= 60
        end

        def write_timeout=(timeout)
          if Integer(timeout) <= 0
            raise 'write_timeout must be greater than 0, %s is given' % timeout
          end
          @write_timeout = timeout
        end

        def max_retries
          @max_retries ||= 5
        end

        def max_retries=(retries)
          if Integer(retries) < 0
            raise 'max_retries must be greater than or equal to 0, %s is given' % retries
          end
          @max_retries = retries
        end
      end
    end

    def self.endpoint_url
      if live_token?
        'https://public.api.socio.events'
      else
        'https://public.sandbox-api.socio.events'
      end
    end

    def self.live_token?
      assert_access_token!
      /\Ask_live_.+/.match?(Webex::Events::Config.access_token)
    end

    def self.sandbox_token?
      assert_access_token!
      !live_token?
    end

    def self.assert_access_token!
      return unless Events::Config.access_token.nil?
      raise 'Access Token is not present. Please set your access token to use the SDK.'
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

    def self.user_agent
      os = RbConfig::CONFIG['host_os']
      hostname = Socket.gethostname
      "Webex Ruby SDK(v#{Webex::Events::VERSION}) - OS(#{os}) - hostname(#{hostname}) - Ruby Version(#{ruby_version})"
    end
  end
end
