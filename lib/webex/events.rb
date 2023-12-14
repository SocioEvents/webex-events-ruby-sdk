# frozen_string_literal: true

require 'faraday'
require 'retriable'
require 'json'
require 'securerandom'
require 'logger'

require_relative 'events/version'
require_relative 'errors/error'
require_relative 'response'
require_relative 'request'
require_relative 'client'
require_relative 'rate_limiter'
require_relative 'helpers'

module Webex
  module Events
    class Config
      class << self
        attr_accessor :access_token
        attr_writer :logger

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

        def logger
          return @logger if @logger
          @logger = Logger.new('/dev/null')
        end
      end
    end
  end
end
