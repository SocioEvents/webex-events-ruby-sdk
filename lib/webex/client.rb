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
    # @param [Hash] variables Query variables
    # @param [String] operation_name GraphQL Operation Name such as TracksConnection
    # @param [Hash] headers
    # @return [Webex::Response]
    def self.query(query:, operation_name:, variables: {}, headers: {})
      Retriable.retriable(on: EXCEPTIONS, tries: 5, intervals: [0.5, 0.8, 1.5, 2, 2.5]) do
        Request.execute(
          query: query,
          variables: variables,
          operation_name: operation_name,
          headers: headers
        )
      end
    end
  end
end
