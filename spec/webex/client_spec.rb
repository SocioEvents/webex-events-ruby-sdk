# frozen_string_literal: true

RSpec.describe Webex::Client do
  before do
    Webex::Events::Config.access_token = 'sk_live_token'
  end

  context 'when an exception is thrown' do
    let(:mock_response) { double status: 429, body: {} }

    it 'does retrying' do
      expect(Webex::Request)
        .to receive(:execute)
              .exactly(5).times
              .and_raise(Webex::Errors::SecondBasedQuotaIsReachedError.new(mock_response))

      expect do
        described_class.query(query: 'query', variables: {}, operation_name: 'TracksConnection')
      end.to raise_error do |error|
        expect(error).to be_a(Webex::Errors::SecondBasedQuotaIsReachedError)
      end
    end

    it 'fails instantly' do
      expect(Webex::Request)
        .to receive(:execute)
              .once
              .and_raise(StandardError)

      expect do
        described_class.query(query: 'query', variables: {}, operation_name: 'TracksConnection')
      end.to raise_error(StandardError)
    end
  end

  context 'when the request is OK' do
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
    let(:url) { Webex::Events.endpoint_url + '/graphql' }
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'Authorization' => 'Bearer %s' % Webex::Events::Config.access_token,
        'X-Sdk-Name' => 'Ruby SDK',
        'X-Sdk-version' => Webex::Events::VERSION,
        'X-Sdk-Lang-Version' => Webex::Events.ruby_version
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

    context 'when the first request ok OK' do
      it 'returns Webex::Request object with correct details' do
        data = {
          data: {
            eventsConnection: {
              edges: []
            }
          }
        }.to_json
        stub = stub_request(:post, url).
          with(
            body: @body.to_json,
            headers: headers
          ).
          to_return(status: 200, body: data)

        response = described_class.query(
          query: gql_query,
          variables: variables,
          operation_name: operation_name,
          headers: {}
        )
        expect(response.body.to_json).to eql(data)
        expect(response).to be_success
        expect(response.time_spent_in_ms).to be > 0
        expect(response.retry_count).to eql(0)
        expect(stub).to have_been_requested
      end
    end

    context 'when the first request is not OK but the second is' do
      let(:mock_response) { double status: 409, body: {} }

      it 'retries the request and returns Webex::Request object with correct details' do
        expect(Webex::Request).to receive(:execute).once.and_raise(Webex::Errors::ConflictError, mock_response) # First request is boom.
        expect(Webex::Request).to receive(:execute).and_call_original.once # Second is OK
        data = {
          data: {
            eventsConnection: {
              edges: []
            }
          }
        }.to_json
        success_stub = stub_request(:post, url).
          with(
            body: @body.to_json,
            headers: headers
          ).
          to_return(status: 200, body: data)

        response = described_class.query(
          query: gql_query,
          variables: variables,
          operation_name: operation_name,
          headers: {}
        )
        expect(response.body.to_json).to eql(data)
        expect(response).to be_success
        expect(response.time_spent_in_ms).to be > 0
        expect(response.retry_count).to eql(1)

        expect(success_stub).to have_been_requested
      end
    end
  end
end

