# frozen_string_literal: true

module Webex
  class RateLimiter
    attr_reader :headers, :used_second_based_cost, :second_based_cost_threshold
    attr_reader :used_daily_based_cost, :daily_based_cost_threshold
    attr_reader :daily_retry_after_in_second, :secondly_retry_after_in_ms

    def initialize(headers)
      @headers = headers
      parse_second_based_cost
      parse_daily_based_cost
      parse_daily_retry_after
      parse_daily_retry_after
      parse_secondly_retry_after
    end

    def parse_secondly_retry_after
      if (value = headers[:HTTP_X_SECONDLY_RETRY_AFTER])
        @secondly_retry_after_in_ms = Integer(value)
      end
    end

    def parse_daily_retry_after
      if (value = headers[:HTTP_X_DAILY_RETRY_AFTER])
        @daily_retry_after_in_second = Integer(value)
      end
    end

    def parse_daily_based_cost
      if (value = headers[:HTTP_X_DAILY_CALL_LIMIT])
        used, threshold = value.split('/')
        @used_daily_based_cost = Integer(used)
        @daily_based_cost_threshold = Integer(threshold)
      end
    end

    def parse_second_based_cost
      if (value = headers[:HTTP_X_SECONDLY_CALL_LIMIT])
        used, threshold = value.split('/')
        @used_second_based_cost = Integer(used)
        @second_based_cost_threshold = Integer(threshold)
      end
    end
  end
end
