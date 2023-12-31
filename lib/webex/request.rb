# frozen_string_literal: true

module Webex
  class Request
    CLIENT_ERROR_STATUSES = (400...500).freeze
    SERVER_ERROR_STATUSES = (500...600).freeze

    # @param [String] query
    # @param [Hash] variables
    # @param [String] operation_name
    # @param [Hash] options
    def initialize(query:, variables:, operation_name:, options: {})
      @query = query
      @variables = variables
      @operation_name = operation_name
      @options = options
      @access_token = Webex::Events::Config.access_token
      @connection = self.class.connection
    end

    # Executes GraphQL query
    # @raise Webex::Errors::Error
    # @return [Webex::Response]
    def execute
      response = @connection.post do |request|
        request.url '/graphql'
        request.body = {
          query: @query,
          variables: @variables,
          operationName: @operation_name
        }.to_json

        request.headers.merge!('Idempotency-Key' => @options[:idempotency_key]) if @options[:idempotency_key]
        request.headers['Content-Type'] = 'application/json'
        request.headers['Authorization'] = 'Bearer %s' % @access_token
        request.headers['X-Sdk-Name'] = 'Ruby SDK'
        request.headers['X-Sdk-Version'] = Webex::Events::VERSION
        request.headers['X-Sdk-Lang-Version'] = Webex::Helpers.ruby_version
        request.headers['User-Agent'] = Webex::Helpers.user_agent
      end

      response = Webex::Response.new(response)
      return response if response.success?

      Events::Config.logger.error("Request failed. Returned status is #{response.status}. Server response is #{response.body}")
      case response.status
      when 400
        case response.body.dig('extensions', 'code')
        when 'INVALID_TOKEN'
          raise Errors::InvalidAccessTokenError.new(response)
        when 'TOKEN_IS_EXPIRED'
          raise Errors::AccessTokenIsExpiredError.new(response)
        else
          raise Errors::BadRequestError.new(response)
        end
      when 401
        raise Errors::AuthenticationRequiredError.new(response)
      when 403
        raise Errors::AuthorizationFailedError.new(response)
      when 404
        raise Errors::ResourceNotFoundError.new(response)
      when 408
        raise Errors::RequestTimeoutError.new(response)
      when 409
        raise Errors::ConflictError.new(response)
      when 413
        raise Errors::QueryComplexityIsTooHighError.new(response)
      when 422
        raise Errors::UnprocessableEntityError.new(response)
      when 429
        extensions = response.body['extensions']
        if extensions['dailyAvailableCost'].to_i < 1
          raise Errors::DailyQuotaIsReachedError.new(response)
        end

        if extensions['availableCost'].to_i < 1
          raise Errors::SecondBasedQuotaIsReachedError.new(response)
        end
      when 500
        raise Errors::ServerError.new(response)
      when 502
        raise Errors::BadGatewayError.new(response)
      when 503
        raise Errors::ServiceUnavailableError.new(response)
      when 504
        raise Errors::GatewayTimeoutError.new(response)
      when CLIENT_ERROR_STATUSES
        raise Errors::ClientError.new(response)
      when SERVER_ERROR_STATUSES
        raise Errors::ServerError.new(response)
      when nil
        raise Errors::NilStatusError.new(response)
      end
    end

    # Creates a Faraday connection instance.
    # @return [Faraday::Connection]
    def self.connection
      Thread.current[:webex_events_connection] ||= Faraday.new(url: Webex::Helpers.endpoint_url) do |faraday|
        # faraday.use Faraday::Response::RaiseError
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter

        faraday.options.timeout = Webex::Events::Config.timeout
        faraday.options.open_timeout = Webex::Events::Config.open_timeout
        faraday.options.write_timeout = Webex::Events::Config.write_timeout

        # force SSL/TLS
        faraday.ssl[:verify] = true
        faraday.ssl[:verify_hostname] = true
        faraday.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def self.execute(query:, variables:, operation_name:, options: {})
      new(query: query, variables: variables, operation_name: operation_name, options: options).execute
    end
  end
end
