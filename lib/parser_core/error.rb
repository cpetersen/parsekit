# frozen_string_literal: true

module ParserCore
  # Base error class for ParserCore
  class Error < StandardError; end
  
  # Raised when parsing fails
  class ParseError < Error; end
  
  # Raised when configuration is invalid
  class ConfigError < Error; end
end