# frozen_string_literal: true

module Webex
  class Request
    ClientErrorStatuses = (400...500).freeze
    ServerErrorStatuses = (500...600).freeze
    UUID_REGEX_VALIDATOR = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    def initialize(query:, variables:, operation_name:, headers: {})
      @query = query
      @variables = variables
      @operation_name = operation_name
      @headers = headers
      @access_token = Webex::Events::Config.access_token
      @connection = self.class.connection
      validate_idempotency_key
    end

    def validate_idempotency_key
      unless @headers['Idempotency-Key'].nil?
        raise 'Idempotency-Key must be UUID format' unless UUID_REGEX_VALIDATOR.match?(@headers['Idempotency-Key'])
      end
    end

    # Executes GraphQL query
    # @return [Webex::Response]
    def execute
      response = @connection.post do |request|
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
        request.headers['X-Sdk-Lang-Version'] = Webex::Events.ruby_version
      end

      response = Webex::Response.new(response)
      return response if response.success?

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
      when ClientErrorStatuses
        raise Errors::ClientError.new(response)
      when ServerErrorStatuses
        raise Errors::ServerError.new(response)
      when nil
        raise Errors::NilStatusError.new(response)
      end
    end

    # Creates a Faraday connection instance.
    # @return [Faraday::Connection]
    def self.connection
      Thread.current[:webex_events_connection] ||= Faraday.new(url: url) do |faraday|
        # faraday.use Faraday::Response::RaiseError
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter

        faraday.options.timeout = 30 # seconds
        faraday.options.open_timeout = 10 # seconds

        # force SSL/TLS
        faraday.ssl[:verify] = true
        faraday.ssl[:verify_hostname] = true
        faraday.ssl[:verify_mode] = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def self.url
      if Webex::Events::Config.access_token.match?(/\Ask_live_.+/)
        'https://public-api.api.socio.events'
      else
        'https://public-api.sandbox-api.socio.events'
      end
    end

    def self.execute(query:, variables:, operation_name:, headers: {})
      new(query: query, variables: variables, operation_name: operation_name, headers: headers).execute
    end
  end
end
