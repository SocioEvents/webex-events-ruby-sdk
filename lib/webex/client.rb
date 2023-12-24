# frozen_string_literal: true

module Webex
  class Client
    EXCEPTIONS = [
      Webex::Errors::RequestTimeoutError,
      Webex::Errors::SecondBasedQuotaIsReachedError,
      Webex::Errors::BadGatewayError,
      Webex::Errors::ServiceUnavailableError,
      Webex::Errors::GatewayTimeoutError,
      Webex::Errors::ConflictError
    ].freeze

    # @param [String] query GraphQL query
    # @param [String] operation_name GraphQL Operation Name such as TracksConnection
    # @return [Webex::Response]
    def self.do_introspection_query
      query(query: Helpers.introspection_query, operation_name: 'IntrospectionQuery')
    end

    # @param [String] query GraphQL query
    # @param [Hash] variables Query variables
    # @param [String] operation_name GraphQL Operation Name such as TracksConnection
    # @param [Hash] options
    # @return [Webex::Response]
    def self.query(query:, operation_name:, variables: {}, options: {})
      Webex::Helpers.assert_access_token!

      logger = Events::Config.logger
      logger.info("Begin to HTTP request to #{Webex::Helpers.endpoint_url}...")
      retries = -1
      start_time = Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
      response = Retriable.retriable(on: EXCEPTIONS, tries: Webex::Events::Config.max_retries) do
        retries += 1
        if retries > 0
          logger.info("Retrying the request. Retry count: #{retries}")
        end
        Request.execute(
          query: query,
          variables: variables,
          operation_name: operation_name,
          options: options
        )
      end

      end_time = Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
      response.retry_count = retries
      response.time_spent_in_ms = end_time - start_time
      logger.info("The HTTP request is finished. The request took #{response.time_spent_in_ms} ms.")
      response
    end
  end
end
