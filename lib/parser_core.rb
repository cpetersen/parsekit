# frozen_string_literal: true

require_relative "parser_core/version"

# Load the native extension
begin
  require_relative "parser_core/parser_core"
rescue LoadError
  require "parser_core/parser_core"
end

require_relative "parser_core/error"
require_relative "parser_core/parser"

# ParserCore is a Ruby binding for the parser-core Rust crate
module ParserCore
  class << self
    # Convenience method to parse input directly
    # @param input [String] The input string to parse
    # @param options [Hash] Optional configuration options
    # @option options [Boolean] :strict_mode Enable strict parsing mode
    # @option options [Integer] :max_depth Maximum parsing depth
    # @option options [String] :encoding Input encoding (default: UTF-8)
    # @return [String] The parsed result
    def parse(input, options = {})
      Parser.new(options).parse(input)
    end
    
    # Parse a file
    # @param path [String] Path to the file to parse
    # @param options [Hash] Optional configuration options
    # @return [String] The parsed result
    def parse_file(path, options = {})
      Parser.new(options).parse_file(path)
    end
    
    # Get the native library version
    # @return [String] Version of the native library
    def native_version
      version
    rescue StandardError
      "unknown"
    end
  end
end