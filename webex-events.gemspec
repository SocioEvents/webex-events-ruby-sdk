# frozen_string_literal: true

require_relative 'lib/webex/events/version'

Gem::Specification.new do |spec|
  spec.name = 'webex-events'
  spec.version = Webex::Events::VERSION
  spec.authors = ['Mehmet Yıldız']
  spec.email = ['yildiz@cisco.com']

  spec.summary = 'Webex Events Ruby SDK'
  spec.description = "This gem simplifies to connect the Webex Evnet's public API server."
  spec.homepage = 'https://github.com/SocioEvents/webex-events-ruby-sdk'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/SocioEvents/webex-events-ruby-sdk'
  spec.metadata['changelog_uri'] = 'https://github.com/SocioEvents/webex-events-ruby-sdk/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'retriable', '~> 3.1'

  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rbs'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'standard'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'simplecov'
end
