# frozen_string_literal: true

module Webex
  module Helpers
    module_function

    def endpoint_url
      if live_token?
        'https://public.api.socio.events'
      else
        'https://public.sandbox-api.socio.events'
      end
    end

    def live_token?
      assert_access_token!
      /\Ask_live_.+/.match?(Webex::Events::Config.access_token)
    end

    def sandbox_token?
      assert_access_token!
      !live_token?
    end

    def assert_access_token!
      return unless Events::Config.access_token.nil?
      raise 'Access Token is not present. Please set your access token to use the SDK.'
    end

    def ruby_version
      case RUBY_ENGINE
      when 'ruby'
        "ruby-#{RUBY_VERSION}"
      when 'jruby'
        "jruby-#{JRUBY_VERSION}"
      else
        RUBY_DESCRIPTION
      end
    end

    def user_agent
      return @user_agent if @user_agent

      os = RbConfig::CONFIG['host_os']
      hostname = Socket.gethostname
      @user_agent = "Webex Ruby SDK(v#{Webex::Events::VERSION}) - OS(#{os}) - hostname(#{hostname}) - Ruby Version(#{ruby_version})"
    end

    def introspection_query
      return @introspection_query if @introspection_query
      @introspection_query = <<-QUERY
          query IntrospectionQuery {
            __schema {
              queryType { name }
              mutationType { name }
              subscriptionType { name }
              types {
                ...FullType
              }
              directives {
                name
                description
                locations
                args {
                  ...InputValue
                }
              }
            }
          }
          fragment FullType on __Type {
            kind
            name
            description
            fields(includeDeprecated: true) {
              name
              description
              args {
                ...InputValue
              }
              type {
                ...TypeRef
              }
              isDeprecated
              deprecationReason
            }
            inputFields {
              ...InputValue
            }
            interfaces {
              ...TypeRef
            }
            enumValues(includeDeprecated: true) {
              name
              description
              isDeprecated
              deprecationReason
            }
            possibleTypes {
              ...TypeRef
            }
          }
          fragment InputValue on __InputValue {
            name
            description
            type { ...TypeRef }
            defaultValue
          }
          fragment TypeRef on __Type {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                  ofType {
                    kind
                    name
                    ofType {
                      kind
                      name
                      ofType {
                        kind
                        name
                        ofType {
                          kind
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
      QUERY
    end
  end
end
