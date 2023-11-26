# frozen_string_literal: true

module Webex
  class Error < StandardError
    attr_reader :response, :code, :extensions, :status

    # @param [Webex::Response] response
    def initialize(response)
      @response = response
      @status = response.status
      @message = response.body['message']
      @extensions = response.body['extensions']
      @code = @extensions&.[]('code')
    end
  end

  class ResourceNotFoundError < Error
  end

  class AuthenticationRequiredError < Error
  end

  class AuthorizationFailedError < Error
  end

  class UnprocessableEntityError < Error
  end

  class InvalidAccessTokenError < Error
  end

  class AccessTokenIsExpiredError < Error
  end

  class DailyQuotaIsReachedError < Error
  end

  class SecondBasedQuotaIsReachedError < Error
  end

  class QueryComplexityIsTooHighError < Error
  end

  class RequestTimeoutError < Error
  end

  class BadGatewayError < Error
  end

  class ServiceUnavailableError < Error
  end

  class GatewayTimeoutError < Error
  end

  class ClientError < Error
  end

  class NilStatusError < Error
  end

  class BadRequestError < Error
  end

  class ServerError < Error
    def reference_id
      extensions['referenceId']
    end
  end
end
