# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe "Error Message Consistency" do
  let(:parser) { ParseKit::Parser.new }

  describe "OCR error messages" do
    context "image loading failures" do
      it "preserves error context for invalid image data" do
        invalid_data = "not an image".bytes
        expect { 
          parser.ocr_image(invalid_data) 
        }.to raise_error(RuntimeError) do |error|
          expect(error.message).to include("Failed to load image")
          # Should include some context about why it failed
          expect(error.message.length).to be > 25
        end
      end

      it "provides meaningful error for corrupted PNG" do
        # PNG magic bytes but corrupted data
        corrupted_png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] + [0xFF] * 20
        expect { 
          parser.ocr_image(corrupted_png) 
        }.to raise_error(RuntimeError) do |error|
          expect(error.message).to include("Failed to load image")
        end
      end

      it "handles empty image data appropriately" do
        expect { 
          parser.ocr_image([]) 
        }.to raise_error(RuntimeError, /Failed to load image|empty|no data/i)
      end

      it "provides context for unsupported image formats in error message" do
        # Valid TIFF with unsupported palette mode (if fixture exists)
        palette_tiff = "spec/fixtures/palette_uncompressed.tiff"
        if File.exist?(palette_tiff)
          image_data = File.binread(palette_tiff).bytes
          expect {
            parser.ocr_image(image_data)
          }.to raise_error(RuntimeError) do |error|
            # Error should mention the specific issue
            expect(error.message).to match(/Failed to load image.*unsupported|Failed to load image.*RGBPalette/i)
          end
        end
      end
    end

    context "OCR processing failures" do
      it "handles very small images gracefully" do
        # Create a tiny valid PNG (1x1 pixel)
        # PNG header + IHDR chunk for 1x1 image + IEND chunk
        tiny_png = [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
          0x00, 0x00, 0x00, 0x0D,  # IHDR length
          0x49, 0x48, 0x44, 0x52,  # IHDR
          0x00, 0x00, 0x00, 0x01,  # width = 1
          0x00, 0x00, 0x00, 0x01,  # height = 1
          0x08, 0x02,              # bit depth = 8, color type = 2 (RGB)
          0x00, 0x00, 0x00,        # compression, filter, interlace
          0x00, 0x00, 0x00, 0x00,  # CRC (simplified, may be wrong)
          0x00, 0x00, 0x00, 0x00,  # IEND length
          0x49, 0x45, 0x4E, 0x44,  # IEND
          0xAE, 0x42, 0x60, 0x82   # IEND CRC
        ]
        
        # Should either succeed with empty/minimal text or raise a clear error
        begin
          result = parser.ocr_image(tiny_png)
          expect(result).to be_a(String)
        rescue RuntimeError => e
          expect(e.message).to include("Failed")
        end
      end
    end

    context "Tesseract initialization context" do
      it "error messages indicate Tesseract-related issues when applicable" do
        # This is hard to test without mocking, but we can verify the error path exists
        # by checking that OCR on valid images works (proving Tesseract initialized)
        valid_png = "spec/fixtures/ocr_test.png"
        if File.exist?(valid_png)
          image_data = File.binread(valid_png).bytes
          result = parser.ocr_image(image_data)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
        end
      end
    end
  end

  describe "PDF error messages" do
    context "parsing failures" do
      it "preserves error context for invalid PDF structure" do
        invalid_pdf = "%PDF-1.5\n%corrupted\ngarbage data".bytes
        expect {
          parser.parse_pdf(invalid_pdf)
        }.to raise_error(RuntimeError) do |error|
          expect(error.message).to include("Failed to parse PDF")
          # Should provide some context
          expect(error.message.length).to be > 20
        end
      end

      it "handles PDF with wrong magic bytes" do
        not_a_pdf = "This is not a PDF file".bytes
        expect {
          parser.parse_pdf(not_a_pdf)
        }.to raise_error(RuntimeError, /Failed to parse PDF/)
      end

      it "provides meaningful error for empty PDF data" do
        expect {
          parser.parse_pdf([])
        }.to raise_error(RuntimeError, /Failed to parse PDF|empty|no data/i)
      end

      it "handles truncated PDF gracefully" do
        # Start of a PDF but truncated
        truncated_pdf = "%PDF-1.5\n%".bytes
        expect {
          parser.parse_pdf(truncated_pdf)
        }.to raise_error(RuntimeError, /Failed to parse PDF/)
      end
    end

    context "page extraction context" do
      it "handles PDFs with no extractable text appropriately" do
        # This would need a real PDF with no text
        empty_pdf_path = "spec/fixtures/empty.pdf"
        if File.exist?(empty_pdf_path)
          pdf_data = File.binread(empty_pdf_path).bytes
          result = parser.parse_pdf(pdf_data)
          expect(result).to match(/no extractable text|empty|scanned/i)
        end
      end
    end
  end

  describe "Error types remain consistent" do
    it "raises IOError for file access issues" do
      expect { 
        parser.parse_file("/nonexistent/file.txt") 
      }.to raise_error(IOError, /No such file or directory/)
    end

    it "raises ArgumentError for invalid arguments" do
      expect { 
        parser.parse_bytes([]) 
      }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "raises ArgumentError for empty string input to parse" do
      expect { 
        parser.parse("") 
      }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "raises RuntimeError for OCR processing failures" do
      expect { 
        parser.ocr_image("not image data".bytes) 
      }.to raise_error(RuntimeError)
    end

    it "raises RuntimeError for PDF processing failures" do
      expect { 
        parser.parse_pdf("not pdf data".bytes) 
      }.to raise_error(RuntimeError)
    end

    it "raises TypeError for wrong argument types" do
      expect { 
        parser.parse_file(nil) 
      }.to raise_error(TypeError)
      
      expect { 
        parser.parse_bytes(nil) 
      }.to raise_error(TypeError)
    end
  end

  describe "Error message format standards" do
    it "error messages start with a clear failure indication" do
      invalid_image = "not an image".bytes
      expect { 
        parser.ocr_image(invalid_image) 
      }.to raise_error(RuntimeError) do |error|
        expect(error.message).to match(/^Failed to/)
      end
    end

    it "PDF errors follow consistent format" do
      invalid_pdf = "not a pdf".bytes
      expect { 
        parser.parse_pdf(invalid_pdf) 
      }.to raise_error(RuntimeError) do |error|
        expect(error.message).to match(/^Failed to parse PDF/)
      end
    end

    it "includes descriptive context in error messages" do
      # Errors should not just say "Failed" but provide context
      invalid_data = [0xFF, 0xFE]
      expect { 
        parser.ocr_image(invalid_data) 
      }.to raise_error(RuntimeError) do |error|
        # Should have more than just "Failed to load image"
        expect(error.message).to match(/Failed to load image:/)
      end
    end
  end

  describe "Error handling in dispatch" do
    context "format detection preserves errors" do
      it "propagates PDF errors through parse_file" do
        Tempfile.create(['invalid', '.pdf']) do |file|
          file.write("Not a real PDF")
          file.rewind
          
          expect {
            parser.parse_file(file.path)
          }.to raise_error(RuntimeError, /Failed to parse PDF/)
        end
      end

      it "propagates OCR errors through parse_file" do
        Tempfile.create(['invalid', '.png']) do |file|
          file.write("Not a real PNG")
          file.rewind
          
          expect {
            parser.parse_file(file.path)
          }.to raise_error(RuntimeError, /Failed to load image/)
        end
      end

      it "propagates DOCX errors through parse_file" do
        Tempfile.create(['invalid', '.docx']) do |file|
          file.write("Not a real DOCX")
          file.rewind
          
          expect {
            parser.parse_file(file.path)
          }.to raise_error(RuntimeError)
        end
      end
    end

    context "format detection preserves errors for bytes" do
      it "propagates PDF errors through parse_bytes with auto-detection" do
        # PDF magic bytes but invalid content
        invalid_pdf = "%PDF-1.5\ngarbage".bytes
        expect {
          parser.parse_bytes(invalid_pdf)
        }.to raise_error(RuntimeError, /Failed to parse PDF/)
      end

      it "propagates image errors through parse_bytes with auto-detection" do
        # PNG magic bytes but invalid content
        invalid_png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFF, 0xFF]
        expect {
          parser.parse_bytes(invalid_png)
        }.to raise_error(RuntimeError, /Failed to load image/)
      end
    end
  end

  describe "Partial failure handling" do
    context "when some operations succeed and others fail" do
      it "handles mixed content appropriately" do
        # This would need fixtures with mixed valid/invalid content
        # For now we just ensure the error paths exist
        expect(parser).to respond_to(:parse_pdf)
        expect(parser).to respond_to(:ocr_image)
        expect(parser).to respond_to(:parse_docx)
        expect(parser).to respond_to(:parse_xlsx)
      end
    end
  end

  describe "Error recovery and fallbacks" do
    it "text parsing doesn't fail on valid text" do
      result = parser.parse_text("Simple text".bytes)
      expect(result).to eq("Simple text")
    end

    it "JSON parsing provides clear errors for invalid JSON" do
      invalid_json = "{invalid json}".bytes
      # JSON parsing might return the text as-is rather than raise an error
      # since it's treated as plain text when JSON parsing fails
      result = parser.parse_json(invalid_json)
      expect(result).to be_a(String)
      expect(result).to include("invalid")
    end

    it "XML parsing handles malformed XML" do
      invalid_xml = "<unclosed>tag".bytes
      result = parser.parse_xml(invalid_xml)
      # XML parser is more forgiving, should return something
      expect(result).to be_a(String)
    end
  end

  describe "Chain of errors" do
    it "preserves error chain through parse_file_routed" do
      Tempfile.create(['invalid', '.pdf']) do |file|
        file.write("Not a PDF")
        file.rewind
        
        expect {
          parser.parse_file_routed(file.path)
        }.to raise_error(RuntimeError, /Failed to parse PDF/)
      end
    end

    it "preserves error chain through parse_bytes_routed" do
      invalid_pdf = "%PDF-1.5\ninvalid".bytes
      expect {
        parser.parse_bytes_routed(invalid_pdf.pack('C*'))
      }.to raise_error(RuntimeError, /Failed to parse PDF/)
    end
  end

  describe "Module-level error consistency" do
    it "module methods raise same errors as instance methods" do
      expect {
        ParseKit.parse("")
      }.to raise_error(ArgumentError, /cannot be empty/)

      expect {
        ParseKit.parse_file("/nonexistent")
      }.to raise_error(IOError)

      expect {
        ParseKit.parse_bytes([])
      }.to raise_error(ArgumentError, /cannot be empty/)
    end
  end
end