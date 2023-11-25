# frozen_string_literal: true

module Webex
  class Client
    # @param [String] query GraphQL query
    # @param [Hash] variables Query variables
    # @param [String] operation_name GraphQL Operation Name such as TracksConnection
    def self.query(query:, operation_name:, variables: {})
      Request.new(
        query: query,
        variables: variables,
        operation_name: operation_name
      ).execute
    end
  end
end
