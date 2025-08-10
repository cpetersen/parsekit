#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'parser_core'
require 'benchmark'
require 'json'

puts "ParserCore Ruby - Advanced Examples"
puts "=" * 40

# Example 1: Batch processing
puts "\n1. Batch processing multiple inputs:"
inputs = [
  "First document to parse",
  "Second document with more content",
  "Third document with special characters: @#$%",
  "Fourth document with unicode: 你好世界 🌍",
  "Fifth document with numbers: 12345"
]

parser = ParserCore::Parser.new(strict_mode: false, max_depth: 150)
results = inputs.map.with_index do |input, i|
  result = parser.parse(input)
  puts "   Document #{i + 1}: #{result[0..50]}..."
  result
end

# Example 2: Configuration management
puts "\n2. Dynamic configuration:"
configs = [
  { strict_mode: true, max_depth: 50, encoding: "UTF-8" },
  { strict_mode: false, max_depth: 100, encoding: "UTF-8" },
  { strict_mode: true, max_depth: 200, encoding: "ASCII" }
]

configs.each_with_index do |config, i|
  parser = ParserCore::Parser.new(config)
  puts "   Config #{i + 1}: #{parser.config}"
  result = parser.parse("Test with config #{i + 1}")
  puts "   Result: #{result}"
end

# Example 3: Performance benchmarking
puts "\n3. Performance benchmarking:"
test_input = "Lorem ipsum dolor sit amet, " * 100
iterations = 1000

time = Benchmark.realtime do
  parser = ParserCore::Parser.new
  iterations.times do
    parser.parse(test_input)
  end
end

puts "   Parsed #{iterations} documents in #{time.round(3)} seconds"
puts "   Average: #{(time / iterations * 1000).round(3)}ms per document"
puts "   Throughput: #{(iterations / time).round(0)} documents/second"

# Example 4: File parsing
puts "\n4. File parsing:"
test_file = "tmp/test_document.txt"
FileUtils.mkdir_p("tmp")
File.write(test_file, "This is a test document for file parsing.\nIt has multiple lines.\nAnd various content.")

begin
  result = ParserCore.parse_file(test_file)
  puts "   File parsed successfully"
  puts "   Result preview: #{result[0..100]}..."
rescue IOError => e
  puts "   Error parsing file: #{e.message}"
ensure
  FileUtils.rm_f(test_file)
end

# Example 5: Custom processing pipeline
puts "\n5. Processing pipeline:"
class DocumentProcessor
  def initialize
    @parser = ParserCore::Parser.new(strict_mode: true)
    @stats = { processed: 0, errors: 0, total_length: 0 }
  end
  
  def process(documents)
    documents.map do |doc|
      begin
        result = @parser.parse(doc)
        @stats[:processed] += 1
        @stats[:total_length] += doc.length
        { status: :success, original: doc, parsed: result }
      rescue => e
        @stats[:errors] += 1
        { status: :error, original: doc, error: e.message }
      end
    end
  end
  
  def stats
    @stats
  end
end

processor = DocumentProcessor.new
documents = [
  "Valid document 1",
  "Valid document 2",
  "", # This will cause an error
  "Valid document 3"
]

results = processor.process(documents)
puts "   Processing stats: #{processor.stats}"
results.each_with_index do |result, i|
  puts "   Doc #{i + 1}: #{result[:status]}"
end

# Example 6: Thread safety demonstration
puts "\n6. Concurrent parsing (thread safety):"
require 'concurrent'

thread_count = 4
docs_per_thread = 25

threads = thread_count.times.map do |i|
  Thread.new do
    parser = ParserCore::Parser.new
    docs_per_thread.times do |j|
      parser.parse("Thread #{i}, Document #{j}")
    end
    i
  end
end

results = threads.map(&:value)
puts "   Successfully parsed documents in #{thread_count} threads"
puts "   Total documents: #{thread_count * docs_per_thread}"

# Example 7: Memory efficiency test
puts "\n7. Memory efficiency:"
require 'objspace'

GC.start
before_memory = ObjectSpace.memsize_of_all

parser = ParserCore::Parser.new
large_input = "x" * 10_000
100.times { parser.parse(large_input) }

GC.start
after_memory = ObjectSpace.memsize_of_all
memory_used = ((after_memory - before_memory) / 1024.0 / 1024.0).round(2)

puts "   Parsed 100 large documents"
puts "   Approximate memory delta: #{memory_used} MB"

# Example 8: Integration example
puts "\n8. Integration with Ruby ecosystem:"
require 'json'

# Simulate parsing JSON-like structure
json_data = { text: "Parse this text", options: { mode: "strict" } }.to_json
puts "   JSON input: #{json_data}"

data = JSON.parse(json_data)
parser = ParserCore::Parser.new(strict_mode: data["options"]["mode"] == "strict")
result = parser.parse(data["text"])
puts "   Parsed result: #{result}"

# Create output structure
output = {
  input: data,
  result: result,
  metadata: {
    parser_version: ParserCore::VERSION,
    timestamp: Time.now.iso8601
  }
}
puts "   Output structure: #{output.to_json[0..100]}..."

puts "\n" + "=" * 40
puts "Advanced examples completed successfully!"