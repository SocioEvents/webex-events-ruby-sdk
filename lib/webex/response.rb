# frozen_string_literal: true

module Webex
  class Response
    attr_reader :status, :body, :headers

    def initialize(faraday_response)
      @status = faraday_response.status
      @body = JSON.parse(faraday_response.body)
      @success = faraday_response.success?
      @headers = faraday_response.headers
    end

    def success?
      @success
    end
  end
end
