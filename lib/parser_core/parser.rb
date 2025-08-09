# frozen_string_literal: true

module ParserCore
  # Ruby wrapper for the native Parser class
  class Parser
    # These methods are implemented in the native extension
    # and are documented here for YARD
    
    # Initialize a new Parser instance
    # @param options [Hash] Configuration options
    # @option options [Boolean] :strict_mode Enable strict parsing mode (default: false)
    # @option options [Integer] :max_depth Maximum parsing depth (default: 100)
    # @option options [String] :encoding Input encoding (default: UTF-8)
    # def initialize(options = {})
    #   # Implemented in native extension
    # end
    
    # Parse an input string
    # @param input [String] The input to parse
    # @return [String] The parsed result
    # @raise [ParseError] If parsing fails
    # def parse(input)
    #   # Implemented in native extension
    # end
    
    # Parse a file
    # @param path [String] Path to the file to parse
    # @return [String] The parsed result
    # @raise [ParseError] If parsing fails
    # @raise [IOError] If file cannot be read
    # def parse_file(path)
    #   # Implemented in native extension
    # end
    
    # Get the current configuration
    # @return [Hash] The parser configuration
    # def config
    #   # Implemented in native extension
    # end
    
    # Check if parser is in strict mode
    # @return [Boolean] True if strict mode is enabled
    # def strict_mode?
    #   # Implemented in native extension
    # end
    
    # Ruby-level helper methods
    
    # Parse with a block for processing results
    # @param input [String] The input to parse
    # @yield [result] Yields the parsed result for processing
    # @return [Object] The block's return value
    def parse_with_block(input)
      result = parse(input)
      yield result if block_given?
      result
    end
    
    # Validate input before parsing
    # @param input [String] The input to validate
    # @return [Boolean] True if input is valid
    def valid_input?(input)
      return false if input.nil? || input.empty?
      return false if input.encoding != Encoding::UTF_8 && config[:encoding] == "UTF-8"
      true
    end
    
    # Create a parser with strict mode enabled
    # @param options [Hash] Additional options
    # @return [Parser] A new parser instance with strict mode
    def self.strict(options = {})
      new(options.merge(strict_mode: true))
    end
  end
end