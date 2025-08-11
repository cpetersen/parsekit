# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe "Simple File Parsing" do
  let(:parser) { ParserCore::Parser.new }

  describe "text file parsing" do
    it "parses text files correctly" do
      Tempfile.create(['test', '.txt']) do |file|
        content = "This is a test file\nWith multiple lines\nAnd UTF-8 content: 你好"
        file.write(content)
        file.rewind
        
        # Test using parse_file
        result = parser.parse_file(file.path)
        expect(result).to eq(content)
        
        # Test using parse_file_routed
        result = parser.parse_file_routed(file.path)
        expect(result).to eq(content)
        
        # Test format detection
        expect(parser.detect_format(file.path)).to eq(:text)
      end
    end

    it "parses text bytes correctly" do
      content = "Plain text content with special chars: €£¥"
      bytes = content.bytes
      
      result = parser.parse_text(bytes)
      expect(result).to eq(content)
    end
  end

  describe "JSON file parsing" do
    it "parses JSON files correctly" do
      Tempfile.create(['test', '.json']) do |file|
        json_data = { "name" => "Test", "value" => 42, "nested" => { "key" => "value" } }
        file.write(json_data.to_json)
        file.rewind
        
        # Test using parse_file
        result = parser.parse_file(file.path)
        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed["name"]).to eq("Test")
        expect(parsed["value"]).to eq(42)
        
        # Test format detection
        expect(parser.detect_format(file.path)).to eq(:json)
      end
    end

    it "parses JSON bytes correctly" do
      json_string = '{"key": "value", "number": 123}'
      bytes = json_string.bytes
      
      result = parser.parse_json(bytes)
      expect(result).to include("key")
      expect(result).to include("value")
      expect(result).to include("123")
      
      # Should be pretty-printed
      expect(result.lines.count).to be > 1
    end

    it "detects JSON from content" do
      json_object = '{"test": "data"}'
      json_array = '[1, 2, 3]'
      
      expect(parser.detect_format_from_bytes(json_object)).to eq(:json)
      expect(parser.detect_format_from_bytes(json_array)).to eq(:json)
    end
  end

  describe "XML parsing" do
    it "parses XML files correctly" do
      Tempfile.create(['test', '.xml']) do |file|
        xml_content = '<?xml version="1.0"?><root><item>Test Content</item><item>Another Item</item></root>'
        file.write(xml_content)
        file.rewind
        
        # Test using parse_file
        result = parser.parse_file(file.path)
        expect(result).to include("Test Content")
        expect(result).to include("Another Item")
        
        # Test format detection
        expect(parser.detect_format(file.path)).to eq(:xml)
      end
    end

    it "parses XML bytes correctly" do
      xml_content = '<?xml version="1.0"?><root><data>Hello World</data></root>'
      bytes = xml_content.bytes
      
      result = parser.parse_xml(bytes)
      expect(result).to include("Hello World")
    end

    it "parses HTML files correctly" do
      Tempfile.create(['test', '.html']) do |file|
        html_content = '<html><body><h1>Title</h1><p>Paragraph text</p></body></html>'
        file.write(html_content)
        file.rewind
        
        result = parser.parse_file(file.path)
        expect(result).to include("Title")
        expect(result).to include("Paragraph text")
        
        # HTML should be detected as XML
        expect(parser.detect_format(file.path)).to eq(:xml)
      end
    end
  end

  describe "CSV handling" do
    it "treats CSV files as text" do
      Tempfile.create(['test', '.csv']) do |file|
        csv_content = "Name,Age,City\nJohn,30,NYC\nJane,25,LA"
        file.write(csv_content)
        file.rewind
        
        result = parser.parse_file(file.path)
        expect(result).to eq(csv_content)
        
        # CSV should be detected as text
        expect(parser.detect_format(file.path)).to eq(:text)
      end
    end
  end

  describe "markdown handling" do
    it "treats markdown files as text" do
      Tempfile.create(['test', '.md']) do |file|
        md_content = "# Header\n\nThis is **bold** and this is *italic*"
        file.write(md_content)
        file.rewind
        
        result = parser.parse_file(file.path)
        expect(result).to eq(md_content)
        
        # Markdown should be detected as text
        expect(parser.detect_format(file.path)).to eq(:text)
      end
    end
  end

  describe "routing methods" do
    it "routes files correctly based on extension" do
      # Test JSON routing
      Tempfile.create(['test', '.json']) do |file|
        file.write('{"test": true}')
        file.rewind
        
        result = parser.parse_file_routed(file.path)
        expect(result).to include('"test"')
        expect(result).to include('true')
      end
    end

    it "routes bytes correctly based on content" do
      # JSON content
      json_data = '{"key": "value"}'
      result = parser.parse_bytes_routed(json_data)
      expect(result).to include("key")
      
      # Plain text content
      text_data = "Plain text"
      result = parser.parse_bytes_routed(text_data)
      expect(result).to eq("Plain text")
      
      # XML content
      xml_data = '<?xml version="1.0"?><root>Content</root>'
      result = parser.parse_bytes_routed(xml_data)
      expect(result).to include("Content")
    end
  end

  describe "encoding handling" do
    it "handles UTF-8 text correctly" do
      content = "Hello 世界 🌍 Здравствуй мир"
      bytes = content.bytes
      
      result = parser.parse_text(bytes)
      expect(result).to eq(content)
    end

    it "handles various encodings in text files" do
      Tempfile.create(['test', '.txt']) do |file|
        content = "Special chars: é à ñ ü ß € £ ¥"
        file.write(content)
        file.rewind
        
        result = parser.parse_file(file.path)
        expect(result).to eq(content)
      end
    end
  end

  describe "module-level convenience methods" do
    it "provides parse_file at module level" do
      Tempfile.create(['test', '.txt']) do |file|
        content = "Module level parsing"
        file.write(content)
        file.rewind
        
        result = ParserCore.parse_file(file.path)
        expect(result).to eq(content)
      end
    end

    it "provides parse_bytes at module level" do
      content = "Byte parsing at module level"
      result = ParserCore.parse_bytes(content.bytes)
      expect(result).to eq(content)
    end
  end

  describe "error handling" do
    it "handles non-existent files" do
      expect {
        parser.parse_file("/non/existent/file.txt")
      }.to raise_error(IOError)
    end

    it "handles empty file paths" do
      expect {
        parser.parse_file("")
      }.to raise_error(IOError)
    end

    it "handles empty byte arrays" do
      expect {
        parser.parse_bytes([])
      }.to raise_error(ArgumentError, /cannot be empty/)
    end
  end
end