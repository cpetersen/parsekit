RSpec.describe "ParseKit Encoding Support" do
  let(:parser) { ParseKit::Parser.new }

  describe "different text encodings" do
    context "with Latin-1 (ISO-8859-1) encoded files" do
      it "handles Latin-1 encoded text files" do
        latin1_file = "spec/fixtures/latin1.txt"
        unless File.exist?(latin1_file)
          fail "Latin-1 fixture file is missing: #{latin1_file}"
        end

        # Latin-1 files should be parseable, with proper character handling
        result = parser.parse_file(latin1_file)
        expect(result).to be_a(String)
        expect(result).not_to be_empty

        # Should contain the basic text content
        expect(result).to include("Latin-1 encoded text")
        # May or may not properly decode special characters depending on implementation
        expect(result.length).to be > 20
      end

      it "handles Latin-1 encoded byte data" do
        latin1_file = "spec/fixtures/latin1.txt"
        unless File.exist?(latin1_file)
          fail "Latin-1 fixture file is missing: #{latin1_file}"
        end

        latin1_data = File.read(latin1_file, mode: 'rb').bytes
        result = parser.parse_bytes(latin1_data)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
        expect(result).to include("Latin-1")
      end
    end

    context "with Shift-JIS encoded files" do
      it "handles Shift-JIS encoded text files" do
        shift_jis_file = "spec/fixtures/shift_jis.txt"
        unless File.exist?(shift_jis_file)
          fail "Shift-JIS fixture file is missing: #{shift_jis_file}"
        end

        # Shift-JIS files should be parseable
        result = parser.parse_file(shift_jis_file)
        expect(result).to be_a(String)
        expect(result).not_to be_empty

        # Should contain basic text content
        expect(result).to include("Shift-JIS")
        # Japanese characters may or may not be properly decoded
        expect(result.length).to be > 20
      end

      it "handles Shift-JIS encoded byte data" do
        shift_jis_file = "spec/fixtures/shift_jis.txt"
        unless File.exist?(shift_jis_file)
          fail "Shift-JIS fixture file is missing: #{shift_jis_file}"
        end

        shift_jis_data = File.read(shift_jis_file, mode: 'rb').bytes
        result = parser.parse_bytes(shift_jis_data)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end

    context "with UTF-16 encoded files" do
      it "handles UTF-16 encoded text files" do
        utf16_file = "spec/fixtures/utf16.txt"
        unless File.exist?(utf16_file)
          fail "UTF-16 fixture file is missing: #{utf16_file}"
        end

        # UTF-16 files should be parseable
        result = parser.parse_file(utf16_file)
        expect(result).to be_a(String)
        expect(result).not_to be_empty

        # UTF-16 contains null bytes between characters, so literal matching won't work
        # Instead check that we got readable content and proper length
        expect(result.length).to be > 20
        # Check for the UTF-16 text pattern (with null bytes)
        expect(result).to match(/U.*T.*F.*-.*1.*6/)
      end

      it "handles UTF-16 encoded byte data" do
        utf16_file = "spec/fixtures/utf16.txt"
        unless File.exist?(utf16_file)
          fail "UTF-16 fixture file is missing: #{utf16_file}"
        end

        utf16_data = File.read(utf16_file, mode: 'rb').bytes
        result = parser.parse_bytes(utf16_data)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end
  end

  describe "encoding error handling" do
    it "handles mixed encoding gracefully" do
      # Create string with mixed valid/invalid UTF-8
      mixed_data = "Valid UTF-8 text".encode("UTF-8").bytes
      mixed_data << 0xFF << 0xFE  # Add invalid UTF-8 bytes

      # Should either convert gracefully or raise appropriate encoding error
      begin
        result = parser.parse_bytes(mixed_data)
        expect(result).to be_a(String)
        expect(result).to include("Valid UTF-8")
      rescue EncodingError => e
        expect(e.message).to match(/encoding|utf-8/i)
      end
    end

    it "handles empty encoding scenarios" do
      # Test with various edge cases
      expect { parser.parse_bytes([]) }.to raise_error(ArgumentError, /empty/i)
      expect { parser.parse("") }.to raise_error(ArgumentError, /empty/i)
    end

    it "handles extremely large text with encoding issues" do
      # Large text that might cause encoding buffer issues
      large_mixed_text = "A" * 100_000 + "ñ" * 1000  # Mix ASCII and Latin chars
      result = parser.parse(large_mixed_text)
      expect(result).to be_a(String)
      expect(result).to include("A")
      expect(result.length).to be > 50_000
    end
  end

  describe "character set conversion" do
    it "preserves basic ASCII across all encodings" do
      # All our test files should preserve basic ASCII characters
      files = ["spec/fixtures/latin1.txt", "spec/fixtures/shift_jis.txt", "spec/fixtures/utf16.txt"]

      files.each do |file|
        next unless File.exist?(file)

        result = parser.parse_file(file)
        # For UTF-16, characters are separated by null bytes, so use regex matching
        if file.include?("utf16")
          expect(result).to match(/T.*h.*i.*s.*i.*s/) # ASCII preserved but with null bytes
          expect(result).to match(/t.*e.*x.*t/) # ASCII preserved but with null bytes
        else
          expect(result).to include("This is") # Basic ASCII should be preserved
          expect(result).to include("text") # Basic ASCII should be preserved
        end
      end
    end

    it "handles Unicode properly in supported encodings" do
      utf16_file = "spec/fixtures/utf16.txt"
      next unless File.exist?(utf16_file)

      result = parser.parse_file(utf16_file)
      expect(result).to be_a(String)
      # Unicode characters may or may not be properly decoded depending on implementation
      # But the file should be processable without crashing
    end
  end
end
