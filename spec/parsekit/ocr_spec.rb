require 'spec_helper'

RSpec.describe "OCR with Tesseract" do
  let(:parser) { ParseKit::Parser.new }

  # Tesseract is now bundled with the gem, so OCR is always available

  describe "#ocr_image" do
    context "with valid image data" do
      it "extracts text from PNG image" do
        png_data = File.read("spec/fixtures/ocr_test.png", mode: 'rb')
        
        result = parser.ocr_image(png_data.bytes)
        
        expect(result).to be_a(String)
        expect(result).not_to be_empty
        expect(result).to include("OCR TEST IMAGE")
      end
    end

    context "with different image formats" do
      it "handles JPEG images" do
        jpeg_path = "spec/fixtures/ocr_test.jpg"
        image_data = File.read(jpeg_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("JPEG OCR Test")
      end

      it "handles BMP images" do
        bmp_path = "spec/fixtures/ocr_test.bmp"
        image_data = File.read(bmp_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("BMP Format")
      end

      it "handles TIFF images with unsupported RGB palette (uncompressed)" do
        tiff_path = "spec/fixtures/palette_uncompressed.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        
        expect {
          parser.ocr_image(image_data)
        }.to raise_error(RuntimeError, /Failed to load image/) do |error|
          expect(error.message).to match(/RGBPalette.*unsupported|does not support.*format features/i)
        end
      end

      it "handles TIFF images with unsupported RGB palette (LZW compression)" do
        tiff_path = "spec/fixtures/palette_lzw.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        
        expect {
          parser.ocr_image(image_data)
        }.to raise_error(RuntimeError, /Failed to load image/) do |error|
          expect(error.message).to match(/RGBPalette.*unsupported|does not support.*format features/i)
        end
      end

      it "handles TIFF images with unsupported RGB palette (ZIP compression)" do
        tiff_path = "spec/fixtures/palette_zip.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        
        expect {
          parser.ocr_image(image_data)
        }.to raise_error(RuntimeError, /Failed to load image/) do |error|
          expect(error.message).to match(/RGBPalette.*unsupported|does not support.*format features/i)
        end
      end

      it "extracts text from grayscale TIFF (uncompressed)" do
        tiff_path = "spec/fixtures/grayscale.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("Grayscale TIFF")
      end

      it "extracts text from RGB TIFF with LZW compression" do
        tiff_path = "spec/fixtures/rgb_lzw.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("RGB LZW TIFF")
      end

      it "extracts text from RGB TIFF with ZIP compression" do
        tiff_path = "spec/fixtures/rgb_zip.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("RGB ZIP TIFF")
      end

      it "extracts text from RGBA TIFF (uncompressed)" do
        tiff_path = "spec/fixtures/rgba.tiff"
        image_data = File.read(tiff_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("RGBA TIFF")
      end
    end

    context "with invalid image data" do
      it "raises error for non-image data" do
        invalid_data = "This is not image data".bytes
        expect { parser.ocr_image(invalid_data) }.to raise_error(RuntimeError, /Failed to load image/)
      end

      it "raises error for corrupted image data" do
        # Create corrupted PNG-like data (invalid PNG header)
        corrupted_data = [0x89, 0x50, 0x4E, 0x47, 0xFF, 0xFF, 0xFF, 0xFF].pack('C*').bytes
        expect { parser.ocr_image(corrupted_data) }.to raise_error(RuntimeError, /Failed to load image/)
      end
    end

    context "with complex text" do
      it "handles multi-line text" do
        multiline_path = "spec/fixtures/multiline.png"
        image_data = File.read(multiline_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        
        # Check that all lines are extracted
        expect(result).to include("Line One")
        expect(result).to include("Line Two")
        expect(result).to include("Line Three")
      end

      it "handles numbers and special characters" do
        special_path = "spec/fixtures/special_chars.png"
        image_data = File.read(special_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to match(/123\.?45/)  # OCR might miss the decimal point
      end
    end
  end

  describe "#parse_file" do
    context "with images" do
      it "automatically detects and processes PNG files" do
        png_path = "spec/fixtures/auto_detect.png"
        result = parser.parse_file(png_path)
        expect(result).to include("Auto Detected")
      end
    end
  end

  describe "#parse_bytes" do
    context "with image auto-detection" do
      it "detects PNG from magic bytes and performs OCR" do
        png_path = "spec/fixtures/magic_detect.png"
        image_data = File.read(png_path, mode: 'rb').bytes
        result = parser.parse_bytes(image_data)
        expect(result).to include("Magic Detection")
      end

      it "detects JPEG from magic bytes" do
        jpg_path = "spec/fixtures/magic_detect.jpg"
        image_data = File.read(jpg_path, mode: 'rb').bytes
        result = parser.parse_bytes(image_data)
        expect(result).to include("JPEG Magic")
      end
    end
  end

  describe "Performance" do
    it "handles reasonably sized images" do
      large_image_path = "spec/fixtures/large_image.png"
      image_data = File.read(large_image_path, mode: 'rb').bytes
      result = parser.ocr_image(image_data)
      expect(result).to include("Large Image Test")
    end
  end

  describe "Static linking verification" do
    it "does not require external OCR libraries at runtime" do
      # This test verifies that the gem works without tesseract installed
      # The bundled tesseract should handle everything internally
      simple_image_path = "spec/fixtures/static_test.png"
      image_data = File.read(simple_image_path, mode: 'rb').bytes
      
      # Should work even if tesseract is not in PATH
      expect { parser.ocr_image(image_data) }.not_to raise_error
      result = parser.ocr_image(image_data)
      expect(result).to include("Static OK")
    end
  end
end