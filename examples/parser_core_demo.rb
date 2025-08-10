#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'parser_core'

puts "ParserCore Ruby - Document Parsing Demo"
puts "=" * 40
puts "This gem wraps the parser-core Rust crate for document text extraction."
puts ""

# Note: This requires system libraries to be installed
# See DEPENDENCIES.md for installation instructions

# Example 1: Parse text input (fallback behavior)
puts "1. Parsing plain text:"
text = "This is plain text input"
result = ParserCore.parse(text)
puts "   Input: #{text}"
puts "   Result: #{result}"
puts ""

# Example 2: Demonstrate what parser-core is designed for
puts "2. Document parsing capabilities:"
puts "   parser-core can extract text from:"
puts "   - PDF files (.pdf)"
puts "   - Word documents (.docx, .doc)"
puts "   - Excel spreadsheets (.xlsx, .xls)"
puts "   - PowerPoint presentations (.pptx, .ppt)"
puts "   - Images with text (using OCR)"
puts ""

# Example 3: Parse file (if you have a sample file)
if ARGV[0] && File.exist?(ARGV[0])
  puts "3. Parsing file: #{ARGV[0]}"
  begin
    extracted_text = ParserCore.parse_file(ARGV[0])
    puts "   File size: #{File.size(ARGV[0])} bytes"
    puts "   Extracted text length: #{extracted_text.length} characters"
    
    if extracted_text.empty?
      puts "   No text extracted (file might be empty or contain only images)"
    else
      # Clean up the text for display (remove null bytes, extra whitespace)
      display_text = extracted_text.gsub(/\0/, '').strip
      if display_text.empty?
        puts "   Text extracted but contains only whitespace/control characters"
      else
        puts "   First 500 characters of extracted text:"
        puts "   ---"
        puts display_text[0..500]
        puts "   ---"
        puts "   ..." if display_text.length > 500
      end
    end
  rescue => e
    puts "   Error: #{e.message}"
  end
else
  puts "3. File parsing example:"
  puts "   Usage: ruby #{$0} <document_file>"
  puts "   Example: ruby #{$0} spec/fixtures/sample.pdf"
end

puts ""
puts "4. Using binary data:"
puts "   You can also parse binary data directly:"
puts "   ```ruby"
puts "   data = File.binread('document.pdf')"
puts "   text = ParserCore.parse_bytes(data)"
puts "   ```"

puts ""
puts "=" * 40
puts "Note: Requires system libraries (leptonica, tesseract, poppler)"
puts "See DEPENDENCIES.md for installation instructions"