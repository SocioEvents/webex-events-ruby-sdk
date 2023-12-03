# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'standard/rake'

task default: %i[spec standard]
task :type_check do
  sh 'RBS_TEST_TARGET="Webex::*" RUBYOPT="-rrbs/test/setup" bundle exec rspec --force-color'
end
