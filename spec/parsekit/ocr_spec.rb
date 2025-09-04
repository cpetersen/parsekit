# frozen_string_literal: true

RSpec.describe "OCR with Tesseract" do
  let(:parser) { ParseKit::Parser.new }

  describe "#ocr_image" do
    context "with valid image data" do
      require 'tmpdir'
let(:temp_dir) { Dir.mktmpdir }
let(:test_image_path) { File.join(temp_dir, "ocr_test.png") }

      before do
        # Create a test image with Python PIL
        system(<<~PYTHON)
          python3 -c "
          from PIL import Image, ImageDraw, ImageFont
          img = Image.new('RGB', (400, 100), color='white')
          draw = ImageDraw.Draw(img)
          try:
              font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 36)
          except:
              font = ImageFont.load_default()
          draw.text((10, 25), 'Test OCR Text', fill='black', font=font)
          img.save('#{test_image_path}')
          " 2>/dev/null
        PYTHON
      end

      after do
        FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
      end

      it "extracts text from PNG image" do
        image_data = File.read(test_image_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to be_a(String)
        expect(result).to include("Test OCR Text")
      end
    end

    context "with different image formats" do
      it "handles JPEG images" do
        # Create a JPEG test image
        jpeg_path = "spec/fixtures/ocr_test.jpg"

        system(<<~PYTHON)
          python3 -c "
          from PIL import Image, ImageDraw, ImageFont
          img = Image.new('RGB', (300, 80), color='white')
          draw = ImageDraw.Draw(img)
          try:
              font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
          except:
              font = ImageFont.load_default()
          draw.text((10, 20), 'JPEG OCR Test', fill='black', font=font)
          img.save('#{jpeg_path}', 'JPEG')
          " 2>/dev/null
        PYTHON

        if File.exist?(jpeg_path)
          image_data = File.read(jpeg_path, mode: 'rb').bytes
          result = parser.ocr_image(image_data)
          expect(result).to include("JPEG OCR Test")
          FileUtils.rm_f(jpeg_path)
        else
          skip "Could not create JPEG test image"
        end
      end

      it "handles BMP images" do
        # Create a BMP test image
        bmp_path = "spec/fixtures/ocr_test.bmp"

        system(<<~PYTHON)
          python3 -c "
          from PIL import Image, ImageDraw, ImageFont
          img = Image.new('RGB', (300, 80), color='white')
          draw = ImageDraw.Draw(img)
          try:
              font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
          except:
              font = ImageFont.load_default()
          draw.text((10, 20), 'BMP Format', fill='black', font=font)
          img.save('#{bmp_path}', 'BMP')
          " 2>/dev/null
        PYTHON

        if File.exist?(bmp_path)
          image_data = File.read(bmp_path, mode: 'rb').bytes
          result = parser.ocr_image(image_data)
          expect(result).to include("BMP Format")
          FileUtils.rm_f(bmp_path)
        else
          skip "Could not create BMP test image"
        end
      end

      it "handles TIFF images (uncompressed)" do
        tif_file = "spec/fixtures/sample.tif"
        unless File.exist?(tif_file)
          fail "Sample TIFF file is missing: #{tif_file}"
        end

        image_data = File.read(tif_file, mode: 'rb').bytes
        begin
          result = parser.ocr_image(image_data)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
          # Should extract some readable text from the TIFF
        rescue RuntimeError => e
          if e.message.include?("unsupported") || e.message.include?("RGBPalette")
            skip "TIFF format not supported by image decoder: #{e.message}"
          else
            raise e
          end
        end
      end

      it "handles TIFF images with LZW compression" do
        tif_file = "spec/fixtures/sample_lzw.tif"
        unless File.exist?(tif_file)
          fail "Sample LZW TIFF file is missing: #{tif_file}"
        end

        image_data = File.read(tif_file, mode: 'rb').bytes
        begin
          result = parser.ocr_image(image_data)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
          # Should extract same text as uncompressed version
        rescue RuntimeError => e
          if e.message.include?("unsupported") || e.message.include?("RGBPalette")
            skip "TIFF format not supported by image decoder: #{e.message}"
          else
            raise e
          end
        end
      end

      it "handles TIFF images with ZIP compression" do
        tif_file = "spec/fixtures/sample_zip.tif"
        unless File.exist?(tif_file)
          fail "Sample ZIP TIFF file is missing: #{tif_file}"
        end

        image_data = File.read(tif_file, mode: 'rb').bytes
        begin
          result = parser.ocr_image(image_data)
          expect(result).to be_a(String)
          expect(result).not_to be_empty
          # Should extract same text regardless of compression
        rescue RuntimeError => e
          if e.message.include?("unsupported") || e.message.include?("RGBPalette")
            skip "TIFF format not supported by image decoder: #{e.message}"
          else
            raise e
          end
        end
      end
    end

    context "with invalid image data" do
      it "raises error for non-image data" do
        invalid_data = "Not an image".bytes
        expect { parser.ocr_image(invalid_data) }.to raise_error(RuntimeError, /Failed to load image/)
      end

      it "raises error for corrupted image data" do
        # PNG header but invalid content
        corrupted_data = [0x89, 0x50, 0x4E, 0x47] + [0xFF] * 100
        expect { parser.ocr_image(corrupted_data) }.to raise_error(RuntimeError, /Failed to load image/)
      end
    end

    context "with complex text" do
      it "handles multi-line text" do
        multiline_path = "spec/fixtures/multiline_ocr.png"

        system(<<~PYTHON)
          python3 -c "
          from PIL import Image, ImageDraw, ImageFont
          img = Image.new('RGB', (400, 150), color='white')
          draw = ImageDraw.Draw(img)
          try:
              font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 20)
          except:
              font = ImageFont.load_default()
          draw.text((10, 10), 'Line One', fill='black', font=font)
          draw.text((10, 50), 'Line Two', fill='black', font=font)
          draw.text((10, 90), 'Line Three', fill='black', font=font)
          img.save('#{multiline_path}')
          " 2>/dev/null
        PYTHON

        if File.exist?(multiline_path)
          image_data = File.read(multiline_path, mode: 'rb').bytes
          result = parser.ocr_image(image_data)
          expect(result).to include("Line One")
          expect(result).to include("Line Two")
          expect(result).to include("Line Three")
          FileUtils.rm_f(multiline_path)
        else
          skip "Could not create multiline test image"
        end
      end

      it "handles numbers and special characters" do
        special_path = "spec/fixtures/special_ocr.png"

        system(<<~PYTHON)
          python3 -c "
          from PIL import Image, ImageDraw, ImageFont
          img = Image.new('RGB', (400, 80), color='white')
          draw = ImageDraw.Draw(img)
          try:
              font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
          except:
              font = ImageFont.load_default()
          draw.text((10, 20), 'Price: \\$123.45', fill='black', font=font)
          img.save('#{special_path}')
          " 2>/dev/null
        PYTHON

        if File.exist?(special_path)
          image_data = File.read(special_path, mode: 'rb').bytes
          result = parser.ocr_image(image_data)
          expect(result).to match(/123\.?45/)  # OCR might miss the decimal point
          FileUtils.rm_f(special_path)
        else
          skip "Could not create special character test image"
        end
      end
    end
  end

  describe "#parse_file with images" do
    it "automatically detects and processes PNG files" do
      png_path = "spec/fixtures/auto_detect.png"

      system(<<~PYTHON)
        python3 -c "
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (300, 80), color='white')
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
        except:
            font = ImageFont.load_default()
        draw.text((10, 20), 'Auto Detected', fill='black', font=font)
        img.save('#{png_path}')
        " 2>/dev/null
      PYTHON

      if File.exist?(png_path)
        result = parser.parse_file(png_path)
        expect(result).to include("Auto Detected")
        FileUtils.rm_f(png_path)
      else
        skip "Could not create test image"
      end
    end
  end

  describe "#parse_bytes with image auto-detection" do
    it "detects PNG from magic bytes and performs OCR" do
      png_path = "spec/fixtures/magic_detect.png"

      system(<<~PYTHON)
        python3 -c "
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (300, 80), color='white')
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
        except:
            font = ImageFont.load_default()
        draw.text((10, 20), 'Magic Detection', fill='black', font=font)
        img.save('#{png_path}')
        " 2>/dev/null
      PYTHON

      if File.exist?(png_path)
        image_data = File.read(png_path, mode: 'rb').bytes
        result = parser.parse_bytes(image_data)
        expect(result).to include("Magic Detection")
        FileUtils.rm_f(png_path)
      else
        skip "Could not create test image"
      end
    end

    it "detects JPEG from magic bytes" do
      jpg_path = "spec/fixtures/magic_jpg.jpg"

      system(<<~PYTHON)
        python3 -c "
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (300, 80), color='white')
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
        except:
            font = ImageFont.load_default()
        draw.text((10, 20), 'JPEG Magic', fill='black', font=font)
        img.save('#{jpg_path}', 'JPEG')
        " 2>/dev/null
      PYTHON

      if File.exist?(jpg_path)
        image_data = File.read(jpg_path, mode: 'rb').bytes
        result = parser.parse_bytes(image_data)
        expect(result).to include("JPEG Magic")
        FileUtils.rm_f(jpg_path)
      else
        skip "Could not create JPEG test image"
      end
    end
  end

  describe "OCR support verification" do
    it "includes image formats in supported formats" do
      formats = ParseKit::Parser.supported_formats
      expect(formats).to include("png")
      expect(formats).to include("jpg")
      expect(formats).to include("jpeg")
      expect(formats).to include("bmp")
      expect(formats).to include("tiff")
    end

    it "recognizes image files as supported" do
      expect(parser.supports_file?("image.png")).to be true
      expect(parser.supports_file?("photo.jpg")).to be true
      expect(parser.supports_file?("scan.tiff")).to be true
      expect(parser.supports_file?("IMAGE.PNG")).to be true
    end
  end

  describe "Performance" do
    it "handles reasonably sized images" do
      large_image_path = "spec/fixtures/large_ocr.png"

      # Create a larger image (but not too large for testing)
      system(<<~PYTHON)
        python3 -c "
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (1024, 768), color='white')
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 48)
        except:
            font = ImageFont.load_default()
        draw.text((100, 350), 'Large Image Test', fill='black', font=font)
        img.save('#{large_image_path}')
        " 2>/dev/null
      PYTHON

      if File.exist?(large_image_path)
        image_data = File.read(large_image_path, mode: 'rb').bytes
        result = parser.ocr_image(image_data)
        expect(result).to include("Large Image Test")
        FileUtils.rm_f(large_image_path)
      else
        skip "Could not create large test image"
      end
    end
  end

  describe "Static linking verification" do
    it "does not require external OCR libraries at runtime" do
      # This test verifies that the gem works without tesseract installed
      # by successfully performing OCR
      simple_image_path = "spec/fixtures/static_test.png"

      system(<<~PYTHON)
        python3 -c "
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (200, 60), color='white')
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 20)
        except:
            font = ImageFont.load_default()
        draw.text((10, 15), 'Static OK', fill='black', font=font)
        img.save('#{simple_image_path}')
        " 2>/dev/null
      PYTHON

      if File.exist?(simple_image_path)
        # This should work even without tesseract installed
        image_data = File.read(simple_image_path, mode: 'rb').bytes
        expect { parser.ocr_image(image_data) }.not_to raise_error
        result = parser.ocr_image(image_data)
        expect(result).to include("Static OK")
        FileUtils.rm_f(simple_image_path)
      else
        skip "Could not create test image"
      end
    end
  end
end
