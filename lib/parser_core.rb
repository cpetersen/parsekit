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
    # The parse_file and parse_data methods are defined in the native extension
    # We just need to document them here or add wrapper logic if needed
    
    # Convenience method to parse input directly (for text)
    # @param input [String] The input string to parse
    # @param options [Hash] Optional configuration options
    # @option options [String] :encoding Input encoding (default: UTF-8)
    # @return [String] The parsed result
    def parse(input, options = {})
      Parser.new(options).parse(input)
    end
    
    # Get supported file formats
    # @return [Array<String>] List of supported file extensions
    def supported_formats
      Parser.supported_formats
    end
    
    # Check if a file format is supported
    # @param path [String] File path to check
    # @return [Boolean] True if the file format is supported
    def supports_file?(path)
      Parser.new.supports_file?(path)
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