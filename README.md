[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)
[![Webex Events](https://github.com/SocioEvents/webex-events-ruby-sdk/actions/workflows/gem-test.yml/badge.svg)](https://github.com/SocioEvents/webex-events-ruby-sdk/actions)

⚠️ This library has not been released yet. 

[![Webex EVENTS](webex-events-logo-white.svg 'Webex Events')](https://socio.events)

# Webex Events Api Ruby SDK

Webex Events provides a range of additional SDKs to accelerate your development process.
They allow a standardized way for developers to interact with and leverage the features and functionalities. 
Pre-built code modules will help access the APIs with your private keys, simplifying data gathering and update flows.

Requirements
-----------------

- MRI 2.7+, JRuby 9.3+ or TruffleRuby 23+

Installation
-----------------

Via command line:

```ruby
gem install webex-events
```

In your ruby script:

```ruby
require 'webex/events'
```

In your Gemfile:

```ruby
gem 'webex-events'
```

Configuration
-----------------

```ruby
  Webex::Events::Config.configure do |config|
    config.access_token = '<access_token>' # sk_live_ab34... or sk_test_cda1...
    
    # Please set your custom configs, if the default configuration does not meet your needs.
    config.max_retries = 3 # Default is 5. Do not set it if you want the default configuration.
    config.timeout = 30 # Default is 30 seconds
    config.open_timeout = 10 # Default is 10 seconds
    config.write_timeout = 60 # Default is 60 seconds
    config.logger = Logger.new($stdout, level: Logger::DEBUG) # By default logger is off.
  end
```

Usage
-----------------

```ruby
  query = <<-GRAPQH
    query EventsConnection($first: Int) {
        eventsConnection(first: $first){
            edges{
                cursor
                node{
                    id
                    name
                    groups{
                        id
                        name
                    }
                }
            }
        }
    }
  GRAPQH
  response = Webex::Client.query(
          query: query,
          variables: { first: 20 },
          operation_name: 'EventsConnection',
          headers: {}
  )
  event = response.body["data"]["eventsConnection"]["edges"][0]
```

If the request is successful, `Webex::Client.query` will return `Webex::Request` object which has the following methods.

| Method             | Type                                                                                                             |
|--------------------|------------------------------------------------------------------------------------------------------------------|
| `status`           | `Integer`                                                                                                        |
| `headers`          | `Hash`                                                                                                           |
| `body`             | `Hash`                                                                                                           |
| `request_headers`  | `Hash`                                                                                                           |
| `request_body`     | `Hash`                                                                                                           |
| `url`              | `String`                                                                                                         |
| `retry_count`      | `Integer`                                                                                                        |
| `time_spent_in_ms` | `Integer`                                                                                                        |
| `rate_limiter`     | [`Webex::RateLimiter`](https://github.com/SocioEvents/webex-events-ruby-sdk/blob/main/lib/webex/rate_limiter.rb) |


For non 200 status codes, an exception is raised for every status code such as `Webex::Errors::ServerError` for server errors. 
For the flow-control these exceptions should be handled like the following. This is an example for `429` status code.
For the full list please refer to [this](https://github.com/SocioEvents/webex-events-ruby-sdk/blob/main/lib/webex/request.rb#L39) file.
```ruby
begin
  Webex::Client.query(
          query: query,
          variables: { first: 20 },
          operation_name: 'EventsConnection',
          headers: {}
  )  
rescue Webex::Errors::DailyQuotaIsReachedError
  # Do something here
rescue Webex::Errors::SecondBasedQuotaIsReachedError => err
  sleep_time = err.response.headers['X-Secondly-Retry-After'].to_i # In milliseconds
  sleep sleep_time / 1000.to_f
  retry 
end
```
By default, `Webex::Client.query` is retriable under the hood. It retries the request several times for the following exceptions.
```
Webex::Errors::RequestTimeoutError => 408
Webex::Errors::ConflictError => 409
Webex::Errors::SecondBasedQuotaIsReachedError => 429
Webex::Errors::BadGatewayError => 502
Webex::Errors::ServiceUnavailableError => 503
Webex::Errors::GatewayTimeoutError => 504
```
Idempotency
-----------------
The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. 
When doing a mutation request, use an idempotency key. If a connection error occurs, you can repeat 
the request without risk of creating a second object or performing the update twice.

To perform mutation request, you must add a header which contains the idempotency key such as 
`Idempotency-Key: <your key>`. The SDK does not produce an Idempotency Key on behalf of you if it is missed.
The SDK also validates the key on runtime, if it is not valid UUID token it will raise an exception. Here is an example
like the following:

```ruby
query = <<-GRAPHQL
          mutation TrackDelete($input: TrackDeleteInput!) {
            trackDelete(input: $input) {
              success
            }
          }
GRAPHQL

begin
  Webex::Client.query(
    query: query,
    variables: { input: { ids: [1,2,3], eventId: 1 } },
    operation_name: 'TrackDelete',
    headers: { 'Idempotency-Key' => SecureRandom.uuid }
  )
rescue Webex::Errors::ConflictError # Conflict errors are retriable, but to guarantee it you can handle the exception again.
  sleep 0.2
  retry
end
```

Telemetry Data Collection
-----------------
Webex Events collects telemetry data, including hostname, operating system, language and SDK version, via API requests. 
This information allows us to improve our services and track any usage-related faults/issues. We handle all data with 
the utmost respect for your privacy. For more details, please refer to the Privacy Policy at https://www.cisco.com/c/en/us/about/legal/privacy-full.html

Development
-----------------

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Contributing
-----------------
Please see the [contributing guidelines](CONTRIBUTING.md).

License
-----------------

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Code of Conduct
-----------------

Everyone interacting in the Webex Events API project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SocioEvents/webex-events-ruby-sdk/blob/main/CODE_OF_CONDUCT.md).
