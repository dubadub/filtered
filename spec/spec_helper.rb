require "bundler/setup"
require "filtered"

require "rubygems"
require "bundler/setup"

Bundler.require

# Add support to load paths
$LOAD_PATH.unshift File.expand_path("support", __dir__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # config.filter_run focus: true

  config.include SQLHelpers
end
