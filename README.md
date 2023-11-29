[![Webex Events](https://github.com/SocioEvents/webex-events-ruby-sdk/actions/workflows/gem-push.yml/badge.svg)](https://github.com/SocioEvents/backend-attendee/actions/workflows/development.yaml)
# Webex Events Api

TODO: 
## Installation

Via command line:

```ruby
gem install webex-events
```

In your ruby script:

```ruby
require 'webex-events'
```

In your Gemfile:

```ruby
gem 'webex-events'
```

## Configuration
```ruby
  Webex::Events::Config.configure do |config|
    config.access_token = '<access_token>' # sk_live_ab34... or sk_test_cda1...
    config.max_retries = 3 # Default is 5. Do not set it if you want the default configuration.
  end
```

## Usage
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
## Idempotency
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
    variables: { input: { trackId: 1, eventId: 1 } },
    operation_name: 'TrackDelete',
    headers: { 'Idempotency-Key' => SecureRandom.uuid }
  )
rescue Webex::Errors::ConflictError # Conflict errors are retriable, but to guarantee it you can handle the exception again.
  sleep 0.2
  retry
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SocioEvents/webex-events-ruby-sdk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/SocioEvents/webex-events-ruby-sdk/blob/main/CODE_OF_CONDUCT.md).

### Pull Requests
* Read [how to properly contribute to open source projects on Github][2].
* Fork the project.
* Use a topic/feature branch to easily amend a pull request later, if necessary.
* Write [good commit messages][3].
* Use the same coding conventions as the rest of the project.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it.
* Add an entry to the [Changelog](CHANGELOG.md) accordingly.
* Make sure the test suite is passing and the code you wrote doesn't produce
  RuboCop offenses.
* [Squash related commits together][5].
* Open a [pull request][4] that relates to *only* one subject with a clear title
  and description in grammatically correct, complete sentences.
## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Webex Events API project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SocioEvents/webex-events-ruby-sdk/blob/main/CODE_OF_CONDUCT.md).


[2]: http://gun.io/blog/how-to-github-fork-branch-and-pull-request
[3]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[4]: https://help.github.com/articles/using-pull-requests
[5]: http://gitready.com/advanced/2009/02/10/squashing-commits-with-rebase.html
