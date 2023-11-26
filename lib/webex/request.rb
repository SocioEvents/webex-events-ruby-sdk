# frozen_string_literal: true

module Webex
  class Request
    ClientErrorStatuses = (400...500).freeze
    ServerErrorStatuses = (500...600).freeze

    def initialize(query:, variables:, operation_name:, headers: {})
      @query = query
      @variables = variables
      @operation_name = operation_name
      @headers = headers
      @access_token = Webex::Events::Config.access_token
      @connection = self.class.connection
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
          raise InvalidAccessTokenError.new(response)
        when 'TOKEN_IS_EXPIRED'
          raise AccessTokenIsExpiredError.new(response)
        else
          raise BadRequestError.new(response)
        end
      when 401
        raise AuthenticationRequiredError.new(response)
      when 403
        raise AuthorizationFailedError.new(response)
      when 404
        raise ResourceNotFoundError.new(response)
      when 408
        raise RequestTimeoutError.new(response)
      when 413
        raise QueryComplexityIsTooHighError.new(response)
      when 422
        raise UnprocessableEntityError.new(response)
      when 429
        extensions = response.body['extensions']
        if extensions['dailyAvailableCost'].to_i < 1
          raise DailyQuotaIsReachedError.new(response)
        end

        if extensions['availableCost'].to_i < 1
          raise SecondBasedQuotaIsReachedError.new(response)
        else
          raise QueryComplexityIsTooHighError.new response
        end
      when 500
        raise ServerError.new(response)
      when 502
        raise BadGatewayError.new(response)
      when 503
        raise ServiceUnavailableError.new(response)
      when 504
        raise GatewayTimeoutError.new(response)
      when ClientErrorStatuses
        raise ClientError.new(response)
      when ServerErrorStatuses
        raise ServerError.new(response)
      when nil
        raise NilStatusError.new(response)
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
  end
end
