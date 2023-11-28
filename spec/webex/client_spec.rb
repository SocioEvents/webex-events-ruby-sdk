# frozen_string_literal: true

RSpec.describe Webex::Client do
  before do
    Webex::Events::Config.access_token = 'sk_live_token'
  end

  let(:mock_response) { double status: 429, body: {} }

  it 'does retrying' do
    expect(Webex::Request)
      .to receive(:execute)
      .exactly(6).times
      .and_raise(Webex::Errors::SecondBasedQuotaIsReachedError.new(mock_response))

    expect do
      described_class.query(query: 'query', variables: {}, operation_name: 'TracksConnection')
    end.to raise_error(Webex::Errors::SecondBasedQuotaIsReachedError)
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
