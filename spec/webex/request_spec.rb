# frozen_string_literal: true

RSpec.describe Webex::Request do
  let(:gql_query) {
    <<-GRAPHQL
      query EventsConnection($first: Int) {
          eventsConnection(first: $first){
              edges{
                  cursor
                  node{
                      id
                      name
                  }
              }
          }
      }
    GRAPHQL
  }
  let(:variables) { { first: 20 } }
  let(:operation_name) { 'EventsConnection' }
  let(:idempotency_key) { SecureRandom.uuid }
  let(:url) { Webex::Events.endpoint_url + '/graphql' }
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'Authorization' => 'Bearer %s' % Webex::Events::Config.access_token,
      'X-Sdk-Name' => 'Ruby SDK',
      'X-Sdk-version' => Webex::Events::VERSION,
      'X-Sdk-Lang-Version' => Webex::Events.ruby_version,
      'Idempotency-Key' => idempotency_key
    }
  end

  before do
    Webex::Events::Config.access_token = 'sk_live_test_token'
    @body = {
      query: gql_query,
      variables: variables,
      operation_name: operation_name
    }
  end

  def do_request
    described_class.new(
      query: gql_query,
      variables: variables,
      operation_name: operation_name,
      headers: { 'Idempotency-Key' => idempotency_key }
    ).execute
  end

  context 'with status code 200' do
    it 'returns the payload' do
      data = {
        data: {
          eventsConnection: {
            edges: []
          }
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 200)

      response = described_class.new(
        query: gql_query,
        variables: variables,
        operation_name: operation_name,
        headers: { 'Idempotency-Key' => idempotency_key }
      ).execute
      expect(response.body.to_json).to eql(data)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 400 with INVALID_TOKEN extension code' do
    it 'raises InvalidAccessToken exception' do
      data = {
        message: 'Access Token is invalid',
        extensions: {
          code: :INVALID_TOKEN
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 400)

      expect do
        do_request
      end.to raise_error(Webex::Errors::InvalidAccessTokenError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 400 with TOKEN_IS_EXPIRED extension code' do
    it 'raises AccessTokenIsExpired exception' do
      data = {
        message: 'Access Token is expired',
        extensions: {
          code: :TOKEN_IS_EXPIRED
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 400)

      expect do
        do_request
      end.to raise_error(Webex::Errors::AccessTokenIsExpiredError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 400 with BAD_REQUEST extension code' do
    it 'raises BadRequestError exception' do
      data = {
        message: 'Bad Request',
        extensions: {
          code: :BAD_REQUEST
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 400)

      expect do
        do_request
      end.to raise_error(Webex::Errors::BadRequestError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 401' do
    it 'raises AuthenticationRequiredError exception' do
      data = {
        message: 'Access Token is required',
        extensions: {
          code: :TOKEN_IS_REQUIRED
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 401)

      expect do
        do_request
      end.to raise_error(Webex::Errors::AuthenticationRequiredError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 403' do
    it 'raises AuthorizationFailedError exception' do
      data = {
        message: 'User does not have access',
        extensions: {
          code: :UNAUTHORIZED
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 403)

      expect do
        do_request
      end.to raise_error(Webex::Errors::AuthorizationFailedError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 404' do
    it 'raises ResourceNotFoundError exception' do
      data = {
        message: 'Not found',
        extensions: {
          code: :RECORD_NOT_FOUND
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 404)

      expect do
        do_request
      end.to raise_error(Webex::Errors::ResourceNotFoundError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 408' do
    it 'raises RequestTimeoutError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 408)

      expect do
        do_request
      end.to raise_error(Webex::Errors::RequestTimeoutError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 409' do
    it 'raises ConflictError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 409)

      expect do
        do_request
      end.to raise_error(Webex::Errors::ConflictError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 413' do
    it 'raises QueryComplexityIsTooHighError exception' do
      data = {
        message: 'Graphql query is too complex',
        extensions: {
          code: :QUERY_TOO_COMPLEX
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 413)

      expect do
        do_request
      end.to raise_error(Webex::Errors::QueryComplexityIsTooHighError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 422' do
    it 'raises UnprocessableEntityError exception' do
      data = {
        message: 'Form is invalid',
        extensions: {
          code: :RECORD_INVALID
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 422)

      expect do
        do_request
      end.to raise_error(Webex::Errors::UnprocessableEntityError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 429' do
    it 'raises DailyQuotaIsReachedError exception' do
      data = {
        message: 'You reached your quota',
        extensions: {
          code: :MAX_COST_EXCEEDED,
          cost: 45,
          availableCost: 5,
          threshold: 50,
          dailyThreshold: 200,
          dailyAvailableCost: 0
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 429)

      expect do
        do_request
      end.to raise_error(Webex::Errors::DailyQuotaIsReachedError)
      expect(stub).to have_been_requested
    end

    it 'raises SecondBasedQuotaIsReachedError exception' do
      data = {
        message: 'You reached your quota',
        extensions: {
          code: :MAX_COST_EXCEEDED,
          cost: 51,
          availableCost: 0,
          threshold: 50,
          dailyThreshold: 200,
          dailyAvailableCost: 190
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 429)

      expect do
        do_request
      end.to raise_error(Webex::Errors::SecondBasedQuotaIsReachedError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 500' do
    it 'raises ServerError exception' do
      data = {
        message: 'Server Error',
        extensions: {
          code: :SERVER_ERROR,
          referenceId: SecureRandom.uuid
        }
      }.to_json
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: data, status: 500)

      expect do
        do_request
      end.to raise_error(Webex::Errors::ServerError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 502' do
    it 'raises BadGatewayError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 502)

      expect do
        do_request
      end.to raise_error(Webex::Errors::BadGatewayError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 503' do
    it 'raises ServiceUnavailableError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 503)

      expect do
        do_request
      end.to raise_error(Webex::Errors::ServiceUnavailableError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 504' do
    it 'raises GatewayTimeoutError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 504)

      expect do
        do_request
      end.to raise_error(Webex::Errors::GatewayTimeoutError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 599' do
    it 'raises ServerError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 599)

      expect do
        do_request
      end.to raise_error(Webex::Errors::ServerError)
      expect(stub).to have_been_requested
    end
  end

  context 'when status code is 499' do
    it 'raises ClientError exception' do
      stub = stub_request(:post, url)
        .with(body: @body.to_json, headers: headers)
        .to_return(body: '', status: 499)

      expect do
        do_request
      end.to raise_error(Webex::Errors::ClientError)
      expect(stub).to have_been_requested
    end
  end

  context 'with idempotency key' do
    context 'when invalid idempotency key' do
      it 'raises exception' do
        expect do
          described_class.new(
            query: gql_query,
            variables: variables,
            operation_name: operation_name,
            headers: { 'Idempotency-Key' => 'Invalid key' }
          ).execute
        end.to raise_error(RuntimeError, /Idempotency-Key must be UUID format/i)
      end
    end

    context 'when valid idempotency key' do
      it 'does the request' do
        stub = stub_request(:post, url)
          .with(body: @body.to_json, headers: headers)
          .to_return(body: {}.to_json, status: 200)

        do_request
        expect(stub).to have_been_requested
      end
    end
  end
end
