RSpec.describe "ParseKit Error Handling" do
  let(:parser) { ParseKit::Parser.new }

  describe "corrupted file handling" do
    context "with corrupted PDF files" do
      it "handles corrupted PDF gracefully" do
        corrupted_pdf = "spec/fixtures/corrupted.pdf"
        unless File.exist?(corrupted_pdf)
          fail "Corrupted PDF fixture is missing: #{corrupted_pdf}"
        end

        # Corrupted PDF should either raise error or return degraded result
        begin
          result = parser.parse_file(corrupted_pdf)
          expect(result).to be_a(String)
          # If it succeeds, it should return some content or error message
        rescue RuntimeError => e
          expect(e.message).to match(/PDF|parse/)
        end
      end

      it "handles corrupted PDF bytes gracefully" do
        corrupted_pdf = "spec/fixtures/corrupted.pdf"
        unless File.exist?(corrupted_pdf)
          fail "Corrupted PDF fixture is missing: #{corrupted_pdf}"
        end

        corrupted_data = File.read(corrupted_pdf, mode: 'rb').bytes
        # Corrupted PDF should either raise error or return degraded result
        begin
          result = parser.parse_bytes(corrupted_data)
          expect(result).to be_a(String)
        rescue RuntimeError => e
          expect(e.message).to match(/PDF|parse/)
        end
      end
    end

    context "with corrupted DOCX files" do
      it "handles corrupted DOCX gracefully" do
        corrupted_docx = "spec/fixtures/corrupted.docx"
        unless File.exist?(corrupted_docx)
          fail "Corrupted DOCX fixture is missing: #{corrupted_docx}"
        end

        expect { parser.parse_file(corrupted_docx) }.to raise_error(RuntimeError)
        # Should detect invalid ZIP structure and raise appropriate error
      end

      it "handles corrupted DOCX bytes gracefully" do
        corrupted_docx = "spec/fixtures/corrupted.docx"
        unless File.exist?(corrupted_docx)
          fail "Corrupted DOCX fixture is missing: #{corrupted_docx}"
        end

        corrupted_data = File.read(corrupted_docx, mode: 'rb').bytes
        expect { parser.parse_bytes(corrupted_data) }.to raise_error(RuntimeError)
      end
    end

    context "with corrupted image files" do
      it "handles corrupted PNG gracefully" do
        corrupted_png = "spec/fixtures/corrupted.png"
        unless File.exist?(corrupted_png)
          fail "Corrupted PNG fixture is missing: #{corrupted_png}"
        end

        expect { parser.parse_file(corrupted_png) }.to raise_error(RuntimeError)
        # Should detect invalid image data and raise OCR error
      end

      it "handles corrupted PNG bytes gracefully" do
        corrupted_png = "spec/fixtures/corrupted.png"
        unless File.exist?(corrupted_png)
          fail "Corrupted PNG fixture is missing: #{corrupted_png}"
        end

        corrupted_data = File.read(corrupted_png, mode: 'rb').bytes
        expect { parser.parse_bytes(corrupted_data) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "file access errors" do
    it "handles non-existent files" do
      expect { parser.parse_file("nonexistent.txt") }.to raise_error(IOError, /No such file or directory/)
    end

    it "handles empty file paths" do
      expect { parser.parse_file("") }.to raise_error
    end

    it "handles nil file paths" do
      expect { parser.parse_file(nil) }.to raise_error
    end
  end

  describe "invalid input handling" do
    it "handles empty byte arrays" do
      expect { parser.parse_bytes([]) }.to raise_error
    end

    it "handles nil byte input" do
      expect { parser.parse_bytes(nil) }.to raise_error
    end

    it "handles malformed string input" do
      # Test with string that has invalid encoding
      invalid_string = "\xFF\xFE\x00\x00Invalid".force_encoding("UTF-8")
      # Should raise encoding error (expected behavior)
      expect { parser.parse(invalid_string) }.to raise_error(EncodingError)
    end
  end

  describe "resource exhaustion scenarios" do
    it "handles extremely long input strings" do
      # Very large string that could cause memory issues
      large_string = "A" * 1_000_000
      result = parser.parse(large_string)
      expect(result).to be_a(String)
      expect(result).to include("A")
    end
  end
end
