# frozen_string_literal: true

# Coverage setup (must be before requiring the gem)
require "simplecov"

# Configure SimpleCov before starting
SimpleCov.configure do
  # Set the root to the project directory
  root File.expand_path("..", __dir__)
  
  # Track files even if not loaded during test run
  track_files "lib/**/*.rb"
  
  add_filter "/spec/"
  add_filter "/ext/"  # Native extensions can't be tracked
  add_filter "/tmp/"
  add_filter "/.bundle/"
  add_filter "/vendor/"
  add_filter %r{/parsekit.bundle}
  
  add_group "Main", "lib/parsekit.rb"
  add_group "Parser", "lib/parsekit/parser.rb"
  add_group "Error", "lib/parsekit/error.rb"
  add_group "Version", "lib/parsekit/version.rb"
  
  # Set coverage thresholds
  minimum_coverage 60
  # minimum_coverage_by_file 50  # Disabled for now due to version.rb
  
  # Use HTML and console formatters
  if ENV["CI"]
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end
  
  # Enable branch coverage
  enable_coverage :branch
end

# Start SimpleCov
SimpleCov.start

require "bundler/setup"
require "parsekit"

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
  config.include ParseKitHelpers if defined?(ParseKitHelpers)

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