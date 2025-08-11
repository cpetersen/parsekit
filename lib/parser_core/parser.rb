# frozen_string_literal: true

module ParserCore
  # Ruby wrapper for the native Parser class
  class Parser
    # These methods are implemented in the native extension
    # and are documented here for YARD
    
    # Initialize a new Parser instance
    # @param options [Hash] Configuration options
    # @option options [String] :encoding Input encoding (default: UTF-8)
    # def initialize(options = {})
    #   # Implemented in native extension
    # end
    
    # Parse an input string (for text content)
    # @param input [String] The input to parse
    # @return [String] The parsed result
    # @raise [ArgumentError] If input is empty
    # def parse(input)
    #   # Implemented in native extension
    # end
    
    # Parse a file (supports PDF, Office documents, text files)
    # @param path [String] Path to the file to parse
    # @return [String] The extracted text content
    # @raise [IOError] If file cannot be read
    # @raise [RuntimeError] If parsing fails
    # def parse_file(path)
    #   # Implemented in native extension
    # end
    
    # Parse binary data
    # @param data [Array<Integer>] Binary data as byte array
    # @return [String] The extracted text content
    # @raise [ArgumentError] If data is empty
    # @raise [RuntimeError] If parsing fails
    # def parse_bytes(data)
    #   # Implemented in native extension
    # end
    
    # Get the current configuration
    # @return [Hash] The parser configuration
    # def config
    #   # Implemented in native extension
    # end
    
    # Check if a file format is supported
    # @param path [String] File path to check
    # @return [Boolean] True if the file format is supported
    # def supports_file?(path)
    #   # Implemented in native extension
    # end
    
    # Get list of supported file formats
    # @return [Array<String>] List of supported file extensions
    # def self.supported_formats
    #   # Implemented in native extension
    # end
    
    # Ruby-level helper methods
    
    # Create a parser with strict mode enabled
    # @param options [Hash] Additional options
    # @return [Parser] A new parser instance with strict mode
    def self.strict(options = {})
      new(options.merge(strict_mode: true))
    end
    
    # Parse a file with a block for processing results
    # @param path [String] Path to the file to parse
    # @yield [result] Yields the parsed result for processing
    # @return [Object] The block's return value
    def parse_file_with_block(path)
      result = parse_file(path)
      yield result if block_given?
      result
    end
    
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
      return false unless input.is_a?(String)
      true
    end
    
    # Validate file before parsing
    # @param path [String] The file path to validate
    # @return [Boolean] True if file exists and format is supported
    def valid_file?(path)
      return false unless File.exist?(path)
      supports_file?(path)
    end
    
    # Get file extension
    # @param path [String] File path
    # @return [String, nil] File extension in lowercase
    def file_extension(path)
      ext = File.extname(path)
      ext.empty? ? nil : ext[1..].downcase
    end
  end
end