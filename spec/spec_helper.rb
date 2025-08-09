# frozen_string_literal: true

# Coverage setup (must be before requiring the gem)
if ENV["COVERAGE"] || ENV["CI"]
  require "simplecov"
  
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/ext/"  # Native extensions can't be tracked
    track_files "lib/**/*.rb"
    
    add_group "Library", "lib/"
    add_group "Extensions", "ext/"
    
    minimum_coverage 90
    minimum_coverage_by_file 80
  end
end

require "bundler/setup"
require "parser_core"

# Support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Filter lines from Ruby gems in backtraces
  config.filter_gems_from_backtrace("bundler")
  
  # Add custom matchers, helpers, etc.
  config.include ParserCoreHelpers if defined?(ParserCoreHelpers)

  # Hooks
  config.before(:suite) do
    # Any setup needed before the entire test suite runs
  end

  config.after(:suite) do
    # Any cleanup needed after the entire test suite runs
  end

  # Focus on specific tests with :focus tag
  config.filter_run_when_matching :focus

  # Show top 10 slowest tests
  config.profile_examples = 10 if ENV["PROFILE"]

  # Use documentation format for CI
  config.formatter = :documentation if ENV["CI"]
end