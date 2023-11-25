# frozen_string_literal: true

module Webex
  class Request
    def initialize(query:, variables:, operation_name:, headers: {})
      @query = query
      @variables = variables
      @operation_name = operation_name
      @headers = headers
      @access_token = Webex::Events::Config.access_token
      @connection = self.class.connection
    end

    def execute
      response = Retriable.retriable do
        connection.post do |request|
          request.url '/graphql'
          request.body = {
            query: @query,
            variables: @variables,
            operation_name: @operation_name
          }.to_json

          request.headers.merge!(@headers)
          request.headers['Content-Type'] = 'application/json'
          request.headers['Authorization'] = 'Bearer %s' % @access_token
          request.headers['X-Sdk-Name'] = 'Ruby SDK'
          request.headers['X-Sdk-Version'] = Webex::Events::VERSION
          request.headers['X-Sdk-Lang-Version'] = RUBY_VERSION
        end
      end

      JSON.parse(response)
    end

    # Creates a Faraday connection instance.
    # @return [Faraday::Connection]
    def self.connection
      Thread.current[:webex_events_connection] ||= Faraday.new(url: url, ssl: { verify: true }) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.url
    end
  end
end
