#!/usr/bin/env ruby
# Example script for parsing various document types with ParserCore
# 
# Usage: ruby parse_documents.rb [file_path]
#
# If no file path is provided, the script will demonstrate parsing
# with sample content for various formats.

require_relative '../lib/parser_core'
require 'tempfile'
require 'json'

def parse_file_example(file_path)
  parser = ParserCore::Parser.new
  
  puts "Parsing file: #{file_path}"
  puts "-" * 50
  
  # Check if file exists
  unless File.exist?(file_path)
    puts "Error: File not found - #{file_path}"
    return
  end
  
  # Detect format
  format = parser.detect_format(file_path)
  puts "Detected format: #{format}"
  
  # Parse the file
  begin
    result = parser.parse_file(file_path)
    
    # Display results based on format
    case format
    when :json
      puts "\nParsed JSON content:"
      puts result
    when :xlsx
      puts "\nExcel content (sheets and data):"
      puts result
    when :docx
      puts "\nWord document text:"
      puts result[0..500] + (result.length > 500 ? "..." : "")
    when :xml, :html
      puts "\nExtracted text from #{format.upcase}:"
      puts result[0..500] + (result.length > 500 ? "..." : "")
    else
      puts "\nContent:"
      puts result[0..500] + (result.length > 500 ? "..." : "")
    end
    
    puts "\nTotal characters: #{result.length}"
    
  rescue => e
    puts "Error parsing file: #{e.message}"
  end
end

def demonstrate_all_formats
  parser = ParserCore::Parser.new
  
  puts "ParserCore Document Parsing Examples"
  puts "=" * 50
  
  # 1. Text file
  puts "\n1. TEXT FILE PARSING"
  puts "-" * 30
  Tempfile.create(['example', '.txt']) do |file|
    content = <<~TEXT
      This is a sample text document.
      It contains multiple lines.
      
      Features:
      - UTF-8 support: 你好世界 🌍
      - Multiple paragraphs
      - Special characters: €£¥
    TEXT
    
    file.write(content)
    file.rewind
    
    result = parser.parse_file(file.path)
    puts "Original length: #{content.length} chars"
    puts "Parsed length: #{result.length} chars"
    puts "Content matches: #{result == content}"
  end
  
  # 2. JSON file
  puts "\n2. JSON FILE PARSING"
  puts "-" * 30
  Tempfile.create(['example', '.json']) do |file|
    json_data = {
      "name" => "ParserCore Example",
      "version" => "1.0.0",
      "features" => ["parsing", "format detection", "pure rust"],
      "metadata" => {
        "created" => Time.now.to_s,
        "author" => "Example User"
      }
    }
    
    file.write(JSON.generate(json_data))
    file.rewind
    
    result = parser.parse_file(file.path)
    puts "Pretty-printed JSON:"
    puts result
  end
  
  # 3. XML file
  puts "\n3. XML FILE PARSING"
  puts "-" * 30
  Tempfile.create(['example', '.xml']) do |file|
    xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <document>
        <title>Sample Document</title>
        <sections>
          <section id="1">
            <heading>Introduction</heading>
            <content>This is the introduction section.</content>
          </section>
          <section id="2">
            <heading>Main Content</heading>
            <content>This is the main content area.</content>
          </section>
        </sections>
      </document>
    XML
    
    file.write(xml_content)
    file.rewind
    
    result = parser.parse_file(file.path)
    puts "Extracted text from XML:"
    puts result
  end
  
  # 4. HTML file
  puts "\n4. HTML FILE PARSING"
  puts "-" * 30
  Tempfile.create(['example', '.html']) do |file|
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Sample Page</title>
      </head>
      <body>
        <h1>Welcome to ParserCore</h1>
        <p>This is a sample HTML document.</p>
        <ul>
          <li>Feature 1</li>
          <li>Feature 2</li>
          <li>Feature 3</li>
        </ul>
      </body>
      </html>
    HTML
    
    file.write(html_content)
    file.rewind
    
    result = parser.parse_file(file.path)
    puts "Extracted text from HTML:"
    puts result
  end
  
  # 5. CSV file (treated as text)
  puts "\n5. CSV FILE PARSING"
  puts "-" * 30
  Tempfile.create(['example', '.csv']) do |file|
    csv_content = <<~CSV
      Name,Age,City,Country
      Alice,30,New York,USA
      Bob,25,London,UK
      Charlie,35,Tokyo,Japan
      Diana,28,Paris,France
    CSV
    
    file.write(csv_content)
    file.rewind
    
    result = parser.parse_file(file.path)
    puts "CSV content (as text):"
    puts result
  end
  
  # 6. Markdown file (treated as text)
  puts "\n6. MARKDOWN FILE PARSING"
  puts "-" * 30
  Tempfile.create(['example', '.md']) do |file|
    md_content = <<~MD
      # ParserCore Example
      
      This is a **markdown** document with *various* formatting.
      
      ## Features
      
      - Bullet points
      - Code blocks
      - Links and images
      
      ```ruby
      puts "Hello from code block"
      ```
    MD
    
    file.write(md_content)
    file.rewind
    
    result = parser.parse_file(file.path)
    puts "Markdown content (as text):"
    puts result
  end
  
  # 7. Format detection examples
  puts "\n7. FORMAT DETECTION"
  puts "-" * 30
  
  test_files = [
    "document.docx",
    "spreadsheet.xlsx",
    "presentation.pdf",
    "data.json",
    "page.html",
    "readme.md",
    "data.csv",
    "unknown.xyz"
  ]
  
  puts "Extension-based detection:"
  test_files.each do |filename|
    format = parser.detect_format(filename)
    puts "  #{filename.ljust(20)} => #{format}"
  end
  
  # 8. Content-based detection
  puts "\n8. CONTENT-BASED DETECTION"
  puts "-" * 30
  
  test_contents = {
    "%PDF-1.4" => "PDF signature",
    "PK\x03\x04" => "ZIP/Office format",
    '{"test": 1}' => "JSON object",
    "[1, 2, 3]" => "JSON array",
    "<?xml " => "XML declaration",
    "<html>" => "HTML tag",
    "Plain text" => "Unknown/text"
  }
  
  puts "Magic byte detection:"
  test_contents.each do |content, description|
    format = parser.detect_format_from_bytes(content)
    display = content.bytes[0..3].map { |b| b < 32 || b > 126 ? "\\x%02X" % b : b.chr }.join
    puts "  #{display.ljust(20)} (#{description}) => #{format}"
  end
  
  # 9. Error handling
  puts "\n9. ERROR HANDLING"
  puts "-" * 30
  
  # Test various error conditions
  errors_tested = []
  
  begin
    parser.parse("")
  rescue ArgumentError => e
    errors_tested << "Empty input: #{e.message}"
  end
  
  begin
    parser.parse_file("/nonexistent/file.txt")
  rescue IOError => e
    errors_tested << "Missing file: #{e.message[0..40]}..."
  end
  
  begin
    parser.parse_bytes([])
  rescue ArgumentError => e
    errors_tested << "Empty bytes: #{e.message}"
  end
  
  puts "Handled errors:"
  errors_tested.each { |err| puts "  ✓ #{err}" }
  
  puts "\n" + "=" * 50
  puts "All examples completed successfully!"
end

# Main execution
if ARGV.empty?
  # No arguments - run demonstration
  demonstrate_all_formats
else
  # Parse the provided file
  file_path = ARGV[0]
  parse_file_example(file_path)
end