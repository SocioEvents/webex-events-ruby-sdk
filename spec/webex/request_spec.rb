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
  let(:url) { described_class.url + '/graphql' }
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
        described_class.new(
          query: gql_query,
          variables: variables,
          operation_name: operation_name,
          headers: { 'Idempotency-Key' => idempotency_key }
        ).execute
      end.to raise_error(Webex::InvalidAccessTokenError)
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
        described_class.new(
          query: gql_query,
          variables: variables,
          operation_name: operation_name,
          headers: { 'Idempotency-Key' => idempotency_key }
        ).execute
      end.to raise_error(Webex::AccessTokenIsExpiredError)
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
        described_class.new(
          query: gql_query,
          variables: variables,
          operation_name: operation_name,
          headers: { 'Idempotency-Key' => idempotency_key }
        ).execute
      end.to raise_error(Webex::BadRequestError)
      expect(stub).to have_been_requested
    end
  end
end
