# frozen_string_literal: true

module ParserCore
  # Ruby wrapper for the native Parser class
  #
  # The Ruby layer now handles format detection and routing to specific parsers,
  # while Rust provides the actual parsing implementations.
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
    
    # Detect format from file path
    # @param path [String] File path
    # @return [Symbol, nil] Format symbol or nil if unknown
    def detect_format(path)
      ext = file_extension(path)
      return nil unless ext
      
      case ext.downcase
      when 'docx' then :docx
      when 'xlsx', 'xls' then :xlsx
      when 'pdf' then :pdf
      when 'json' then :json
      when 'xml', 'html' then :xml
      when 'txt', 'text', 'md', 'markdown' then :text
      when 'csv' then :text  # CSV is handled as text for now
      else :text  # Default to text
      end
    end
    
    # Detect format from binary data
    # @param data [String, Array<Integer>] Binary data
    # @return [Symbol] Format symbol
    def detect_format_from_bytes(data)
      # Convert to bytes if string
      bytes = data.is_a?(String) ? data.bytes : data
      return :text if bytes.empty?
      
      # Check magic bytes
      if bytes[0..3] == [0x25, 0x50, 0x44, 0x46]  # %PDF
        :pdf
      elsif bytes[0..1] == [0x50, 0x4B]  # PK (ZIP archive)
        # Could be DOCX or XLSX, default to xlsx for now
        # In the future, could inspect ZIP contents to determine
        :xlsx
      elsif bytes[0..3] == [0xD0, 0xCF, 0x11, 0xE0]  # Old Excel
        :xlsx
      elsif bytes[0..4] == [0x3C, 0x3F, 0x78, 0x6D, 0x6C]  # <?xml
        :xml
      elsif bytes[0..4] == [0x3C, 0x68, 0x74, 0x6D, 0x6C]  # <html
        :xml
      elsif bytes[0] == 0x7B || bytes[0] == 0x5B  # { or [
        :json
      else
        :text
      end
    end
    
    # Parse file using format-specific parser
    # This method now detects format and routes to the appropriate parser
    # @param path [String] File path
    # @return [String] Parsed content
    def parse_file_routed(path)
      format = detect_format(path)
      data = File.read(path, mode: 'rb').bytes
      
      case format
      when :docx then parse_docx(data)
      when :xlsx then parse_xlsx(data) 
      when :pdf then parse_pdf(data)
      when :json then parse_json(data)
      when :xml then parse_xml(data)
      else parse_text(data)
      end
    end
    
    # Parse bytes using format-specific parser
    # This method detects format and routes to the appropriate parser
    # @param data [String, Array<Integer>] Binary data
    # @return [String] Parsed content
    def parse_bytes_routed(data)
      format = detect_format_from_bytes(data)
      bytes = data.is_a?(String) ? data.bytes : data
      
      case format
      when :docx then parse_docx(bytes)
      when :xlsx then parse_xlsx(bytes)
      when :pdf then parse_pdf(bytes)
      when :json then parse_json(bytes)
      when :xml then parse_xml(bytes)
      else parse_text(bytes)
      end
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
      return false unless input.is_a?(String)
      return false if input.empty?
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