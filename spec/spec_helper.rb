require 'bundler/setup'
require 'test_construct/rspec_integration'

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

Bundler.require :default, :test

def shellout(*args, log_verbose: false, **kwargs)
  Mixlib::ShellOut.new(*args, timeout: 5, **kwargs).run_command.tap(&:error!)
end