#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'parser_core'

puts "ParserCore Ruby - Basic Examples"
puts "=" * 40

# Example 1: Simple parsing
puts "\n1. Simple parsing:"
result = ParserCore.parse("Hello, World!")
puts "   Input: 'Hello, World!'"
puts "   Result: #{result}"

# Example 2: Parsing with options
puts "\n2. Parsing with options:"
result = ParserCore.parse("Advanced text", strict_mode: true, max_depth: 50)
puts "   Input: 'Advanced text'"
puts "   Options: strict_mode: true, max_depth: 50"
puts "   Result: #{result}"

# Example 3: Using Parser instance
puts "\n3. Using Parser instance:"
parser = ParserCore::Parser.new(
  strict_mode: false,
  max_depth: 100,
  encoding: "UTF-8"
)
result = parser.parse("Instance parsing")
puts "   Parser config: #{parser.config}"
puts "   Result: #{result}"

# Example 4: Strict parser
puts "\n4. Strict parser convenience method:"
strict_parser = ParserCore::Parser.strict
puts "   Is strict? #{strict_parser.strict_mode?}"
result = strict_parser.parse("Strict parsing")
puts "   Result: #{result}"

# Example 5: Parse with validation
puts "\n5. Input validation:"
parser = ParserCore::Parser.new
inputs = ["Valid input", "", nil, "Another valid input"]

inputs.each do |input|
  if parser.valid_input?(input)
    result = parser.parse(input)
    puts "   '#{input}' is valid. Result: #{result}"
  else
    puts "   '#{input}' is invalid, skipping."
  end
end

# Example 6: Parse with block
puts "\n6. Parse with block processing:"
parser = ParserCore::Parser.new
result = parser.parse_with_block("Process me") do |parsed|
  puts "   In block: #{parsed}"
  transformed = parsed.upcase
  puts "   Transformed: #{transformed}"
  transformed
end
puts "   Final result: #{result}"

# Example 7: Error handling
puts "\n7. Error handling:"
begin
  ParserCore.parse("")
rescue ArgumentError => e
  puts "   Caught ArgumentError: #{e.message}"
end

begin
  ParserCore.parse(nil)
rescue TypeError => e
  puts "   Caught TypeError: #{e.message}"
end

# Example 8: Native version
puts "\n8. Version information:"
puts "   Gem version: #{ParserCore::VERSION}"
puts "   Native version: #{ParserCore.native_version}"

puts "\n" + "=" * 40
puts "Examples completed successfully!"