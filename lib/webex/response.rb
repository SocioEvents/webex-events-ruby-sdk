# frozen_string_literal: true

module Webex
  class Response
    attr_reader :status, :body, :headers
    attr_reader :request_headers, :request_body, :url

    def initialize(faraday_response)
      @status = faraday_response.status
      @body = JSON.parse(faraday_response.body) rescue {}
      @success = faraday_response.success?
      @headers = faraday_response.headers.to_h
      @request_headers = faraday_response.env[:request_headers].to_h
      @request_body = faraday_response.env[:request_body]
      @url = faraday_response.env[:url]
    end

    def success?
      @success
    end
  end
end
