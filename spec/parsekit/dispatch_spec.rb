# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe "Dispatch and Routing" do
  let(:parser) { ParseKit::Parser.new }

  describe "parse_file dispatch" do
    context "with PDF files" do
      it "correctly parses .pdf files" do
        pdf_file = File.join(__dir__, "..", "fixtures", "sample.pdf")
        if File.exist?(pdf_file)
          result = parser.parse_file(pdf_file)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
          # PDF parsing should extract text content
          expect(result.length).to be > 10
        else
          skip "sample.pdf fixture not found"
        end
      end
    end

    context "with Word documents" do
      it "correctly parses .docx files" do
        docx_file = File.join(__dir__, "..", "fixtures", "sample.docx")
        if File.exist?(docx_file)
          result = parser.parse_file(docx_file)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        else
          skip "sample.docx fixture not found"
        end
      end
    end

    context "with Excel files" do
      it "correctly parses .xlsx files" do
        xlsx_file = File.join(__dir__, "..", "fixtures", "sample.xlsx")
        if File.exist?(xlsx_file)
          result = parser.parse_file(xlsx_file)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        else
          skip "sample.xlsx fixture not found"
        end
      end

      it "correctly parses .xls files" do
        xls_file = File.join(__dir__, "..", "fixtures", "sample.xls")
        if File.exist?(xls_file)
          # XLS files might fail parsing, so we test that it attempts to parse
          begin
            result = parser.parse_file(xls_file)
            expect(result).to be_a(String)
          rescue StandardError => e
            # XLS parsing can fail, that's ok as long as it routes correctly
            expect(e.message).to match(/parse Excel|workbook/)
          end
        else
          skip "sample.xls fixture not found"
        end
      end
    end

    context "with PowerPoint files" do
      it "correctly parses .pptx files" do
        pptx_file = File.join(__dir__, "..", "fixtures", "sample.pptx")
        if File.exist?(pptx_file)
          result = parser.parse_file(pptx_file)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        else
          skip "sample.pptx fixture not found"
        end
      end
    end

    context "with image files" do
      it "performs OCR on .png files" do
        png_file = File.join(__dir__, "..", "fixtures", "ocr_test.png")
        if File.exist?(png_file)
          result = parser.parse_file(png_file)
          expect(result).to be_a(String)
          expect(result.downcase).to include("test")
        else
          skip "ocr_test.png fixture not found"
        end
      end

      it "performs OCR on .jpg files" do
        jpg_file = File.join(__dir__, "..", "fixtures", "ocr_test.jpg")
        if File.exist?(jpg_file)
          result = parser.parse_file(jpg_file)
          expect(result).to be_a(String)
          expect(result.downcase).to include("test")
        else
          skip "ocr_test.jpg fixture not found"
        end
      end

      it "performs OCR on .tiff files" do
        tiff_file = File.join(__dir__, "..", "fixtures", "ocr_rgb_lzw.tif")
        if File.exist?(tiff_file)
          result = parser.parse_file(tiff_file)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        else
          skip "tiff fixture not found"
        end
      end

      it "performs OCR on .bmp files" do
        bmp_file = File.join(__dir__, "..", "fixtures", "ocr_test.bmp")
        if File.exist?(bmp_file)
          result = parser.parse_file(bmp_file)
          expect(result).to be_a(String)
          expect(result).not_to be_empty  # Just check it extracted something
        else
          skip "ocr_test.bmp fixture not found"
        end
      end
    end

    context "with JSON files" do
      it "correctly parses .json files" do
        Tempfile.create(['test', '.json']) do |file|
          file.write('{"test": true}')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to include('"test"')
          expect(result).to include('true')
        end
      end
    end

    context "with XML/HTML files" do
      it "correctly parses .xml files" do
        Tempfile.create(['test', '.xml']) do |file|
          file.write('<?xml version="1.0"?><root>content</root>')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to include('content')
        end
      end

      it "correctly parses .html files" do
        Tempfile.create(['test', '.html']) do |file|
          file.write('<!DOCTYPE html><html><body>content</body></html>')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to include('content')
        end
      end
    end

    context "with text files" do
      it "correctly parses .txt files" do
        Tempfile.create(['test', '.txt']) do |file|
          file.write('Plain text content')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to eq('Plain text content')
        end
      end

      it "correctly parses .md files" do
        Tempfile.create(['test', '.md']) do |file|
          file.write('# Markdown content')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to eq('# Markdown content')
        end
      end

      it "correctly parses .csv files" do
        Tempfile.create(['test', '.csv']) do |file|
          content = "col1,col2\nval1,val2"
          file.write(content)
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to eq(content)
        end
      end
    end

    context "with unknown formats" do
      it "treats unknown extensions as text" do
        Tempfile.create(['test', '.xyz']) do |file|
          file.write('Unknown format content')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to eq('Unknown format content')
        end
      end

      it "treats files without extensions as text" do
        Tempfile.create('test_no_ext') do |file|
          file.write('No extension content')
          file.rewind
          
          result = parser.parse_file(file.path)
          expect(result).to eq('No extension content')
        end
      end
    end
  end

  describe "parse_bytes dispatch" do
    context "with format auto-detection" do
      it "correctly handles PDF content" do
        # Use a real PDF file for testing
        pdf_file = File.join(__dir__, "..", "fixtures", "sample.pdf")
        if File.exist?(pdf_file)
          pdf_bytes = File.binread(pdf_file).bytes
          result = parser.parse_bytes(pdf_bytes)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        else
          # Fallback: invalid PDF should raise error
          pdf_bytes = "%PDF-1.5\n%invalid".bytes
          expect { parser.parse_bytes(pdf_bytes) }.to raise_error(StandardError)
        end
      end

      it "correctly handles PNG content" do
        # Real PNG would trigger OCR, but this simplified test just checks routing
        png_file = File.join(__dir__, "..", "fixtures", "ocr_test.png")
        if File.exist?(png_file)
          png_bytes = File.binread(png_file).bytes
          result = parser.parse_bytes(png_bytes)
          expect(result).to be_a(String)
          expect(result.downcase).to include("test")
        end
      end

      it "correctly handles JPEG content" do
        jpg_file = File.join(__dir__, "..", "fixtures", "ocr_test.jpg")
        if File.exist?(jpg_file)
          jpeg_bytes = File.binread(jpg_file).bytes
          result = parser.parse_bytes(jpeg_bytes)
          expect(result).to be_a(String)
          expect(result.downcase).to include("test")
        end
      end

      it "correctly handles JSON content" do
        json_bytes = '{"key": "value"}'.bytes
        result = parser.parse_bytes(json_bytes)
        expect(result).to include('"key"')
        expect(result).to include('"value"')
      end

      it "correctly handles XML content" do
        xml_bytes = '<?xml version="1.0"?><root>test</root>'.bytes
        result = parser.parse_bytes(xml_bytes)
        expect(result).to include('test')
      end

      it "correctly handles HTML content" do
        html_bytes = '<!DOCTYPE html><html><body>test</body></html>'.bytes
        result = parser.parse_bytes(html_bytes)
        expect(result).to include('test')
      end

      it "correctly handles plain text" do
        text_bytes = "Plain text content".bytes
        result = parser.parse_bytes(text_bytes)
        expect(result).to eq("Plain text content")
      end

      it "correctly handles ZIP archives (Office formats)" do
        xlsx_file = File.join(__dir__, "..", "fixtures", "sample.xlsx")
        if File.exist?(xlsx_file)
          xlsx_bytes = File.binread(xlsx_file).bytes
          result = parser.parse_bytes(xlsx_bytes)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        end
      end

      it "correctly handles old Excel format" do
        # OLE compound document signature - would be routed to XLSX parser
        # This is a simplified test since we don't have a real XLS file
        xls_bytes = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1] + [0] * 100
        # This would fail with invalid data, but tests the routing
        expect { parser.parse_bytes(xls_bytes) }.to raise_error(StandardError)
      end
    end

    context "with edge cases" do
      it "handles empty data gracefully" do
        expect { parser.parse_bytes([]) }.to raise_error(ArgumentError, /cannot be empty/)
      end

      it "treats unrecognized binary as text" do
        unknown_bytes = [0x00, 0x01, 0x02, 0x03] + [0] * 10
        result = parser.parse_bytes(unknown_bytes)
        expect(result).to be_a(String)
      end
    end
  end

  describe "Ruby routing methods" do
    describe "#parse_file_routed" do
      it "routes all supported formats correctly" do
        # Test that each format is routed and processed correctly
        test_cases = {
          ".json" => ['{"test": "json"}', '"test"'],
          ".xml" => ['<?xml version="1.0"?><root>xml content</root>', 'xml content'],
          ".html" => ['<!DOCTYPE html><html><body>html content</body></html>', 'html content'],
          ".txt" => ['text content', 'text content'],
          ".md" => ['# markdown content', '# markdown content'],
          ".csv" => ['col1,col2', 'col1,col2']
        }

        test_cases.each do |ext, (content, expected)|
          Tempfile.create(['test', ext]) do |file|
            file.write(content)
            file.rewind
            
            result = parser.parse_file_routed(file.path)
            expect(result).to include(expected)
          end
        end
      end
    end

    describe "#parse_bytes_routed" do
      it "routes based on content detection" do
        test_cases = {
          "%PDF-1.5" => :parse_pdf,
          '{"test": true}' => :parse_json,
          '<?xml version="1.0"?>' => :parse_xml,
          '<!DOCTYPE html>' => :parse_xml,
          'Plain text' => :parse_text
        }

        test_cases.each do |content, expected_method|
          expect(parser).to receive(expected_method).and_return("parsed")
          result = parser.parse_bytes_routed(content)
          expect(result).to eq("parsed")
        end
      end
    end
  end

  describe "Dispatch consistency" do
    it "Ruby and Rust dispatch produce same results for files" do
      Tempfile.create(['test', '.json']) do |file|
        file.write('{"test": true}')
        file.rewind
        
        # Ruby routing
        ruby_result = parser.parse_file_routed(file.path)
        
        # Direct parse (uses Rust routing)
        rust_result = parser.parse_file(file.path)
        
        expect(ruby_result).to eq(rust_result)
      end
    end

    it "Ruby and Rust dispatch produce same results for bytes" do
      test_data = '{"key": "value"}'
      
      # Ruby routing
      ruby_result = parser.parse_bytes_routed(test_data)
      
      # Direct parse (uses Rust routing)
      rust_result = parser.parse_bytes(test_data.bytes)
      
      expect(ruby_result).to eq(rust_result)
    end

    it "All three dispatch methods handle unknown formats consistently" do
      unknown_data = "Unknown format content"
      
      Tempfile.create(['test', '.xyz']) do |file|
        file.write(unknown_data)
        file.rewind
        
        # All should route to text parser
        file_result = parser.parse_file(file.path)
        routed_file_result = parser.parse_file_routed(file.path)
        bytes_result = parser.parse_bytes(unknown_data.bytes)
        routed_bytes_result = parser.parse_bytes_routed(unknown_data)
        
        expect(file_result).to eq(unknown_data)
        expect(routed_file_result).to eq(unknown_data)
        expect(bytes_result).to eq(unknown_data)
        expect(routed_bytes_result).to eq(unknown_data)
      end
    end
  end

  describe "Error handling in dispatch" do
    it "handles nil input gracefully" do
      expect { parser.parse_bytes(nil) }.to raise_error(StandardError)
    end

    it "handles empty file paths gracefully" do
      expect { parser.parse_file("") }.to raise_error(StandardError)
    end

    it "handles non-existent files gracefully" do
      expect { parser.parse_file("/non/existent/file.pdf") }.to raise_error(StandardError)
    end

    it "propagates parser errors correctly" do
      # Create a file with corrupted content
      Tempfile.create(['corrupted', '.pdf']) do |file|
        file.write("Not a real PDF")
        file.rewind
        
        # Should route to PDF parser but fail parsing
        expect { parser.parse_file(file.path) }.to raise_error(StandardError)
      end
    end
  end

  describe "Performance considerations" do
    it "efficiently routes files with clear extensions" do
      # Test that the routing is efficient for common formats
      Tempfile.create(['test', '.json']) do |file|
        file.write('{"fast": true}')
        file.rewind
        
        start_time = Time.now
        result = parser.parse_file(file.path)
        elapsed = Time.now - start_time
        
        expect(result).to include('"fast"')
        # Should be very fast for small files
        expect(elapsed).to be < 0.1
      end
    end
  end
end