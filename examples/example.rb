# frozen_string_literal: true

require_relative '../lib/webex/events'

def mutation_query
  query = <<-GQL
    mutation TrackDelete($input: TrackDeleteInput!) {
      trackDelete(input: $input) {
        success
      }
    }
  GQL
  variables = {
    input: { ids: [1], eventId: 1 }
  }
  response = Webex::Client.query(query: query, operation_name: 'TrackDelete', variables: variables, options: { idempotency_key: SecureRandom.uuid })
  pp response
end

def single_query
  query = <<-GQL
    query Currency($isoCode: String!) {
      currency(isoCode: $isoCode) {
        isoCode
        name
      }
    }
  GQL
  response = Webex::Client.query(query: query, operation_name: 'Currency', variables: { isoCode: 'USD' }, options: {})
  pp response
end

def get_connection
  query = <<-GQL
      fragment EventStuff on Event {
          id
          name
      }
      query EventsConnection($first: Int){
          eventsConnection(first: $first) {
              edges{
                  cursor
                  node{
                      ...EventStuff
                  }
              }
          }
      }
  GQL

  response = Webex::Client.query(query: query, operation_name: 'EventsConnection', variables: { first: 10 }, options: {})
  pp response
end
