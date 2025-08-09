# frozen_string_literal: true

RSpec.describe "ParserCore Integration" do
  describe "document format support" do
    let(:parser) { ParserCore::Parser.new }

    context "with sample documents" do
      # Note: These tests require actual document files
      # They're marked as pending unless sample files exist
      
      it "extracts text from PDF files" do
        pdf_file = "spec/fixtures/sample.pdf"
        skip "Requires sample PDF file" unless File.exist?(pdf_file)
        
        result = parser.parse_file(pdf_file)
        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end

      it "extracts text from Word documents" do
        docx_file = "spec/fixtures/sample.docx"
        skip "Requires sample DOCX file" unless File.exist?(docx_file)
        
        result = parser.parse_file(docx_file)
        expect(result).to be_a(String)
      end

      it "extracts text from Excel files" do
        xlsx_file = "spec/fixtures/sample.xlsx"
        skip "Requires sample XLSX file" unless File.exist?(xlsx_file)
        
        result = parser.parse_file(xlsx_file)
        expect(result).to be_a(String)
      end

      it "performs OCR on images" do
        image_file = "spec/fixtures/sample.png"
        skip "Requires sample image with text" unless File.exist?(image_file)
        
        result = parser.parse_file(image_file)
        expect(result).to be_a(String)
      end
    end
  end

  describe "batch processing" do
    it "can process multiple files sequentially" do
      files = []
      3.times do |i|
        file = "spec/fixtures/batch_#{i}.txt"
        FileUtils.mkdir_p("spec/fixtures")
        File.write(file, "Content #{i}")
        files << file
      end

      results = files.map { |f| ParserCore.parse_file(f) }
      
      expect(results.size).to eq(3)
      expect(results).to all(be_a(String))
      
      # Clean up temporary batch files
      files.each { |f| File.delete(f) if File.exist?(f) }
    end
  end

  describe "encoding handling" do
    before { FileUtils.mkdir_p("spec/fixtures") }
    after do
      # Clean up temporary test files only
      %w[utf8.txt ascii.txt].each do |f|
        File.delete("spec/fixtures/#{f}") if File.exist?("spec/fixtures/#{f}")
      end
    end

    it "handles UTF-8 encoded files" do
      file = "spec/fixtures/utf8.txt"
      File.write(file, "UTF-8: 世界 мир विश्व", encoding: "UTF-8")
      result = ParserCore.parse_file(file)
      expect(result).to include("UTF-8:")
    end

    it "handles ASCII encoded files" do
      file = "spec/fixtures/ascii.txt"
      File.write(file, "ASCII text only", encoding: "ASCII")
      result = ParserCore.parse_file(file)
      expect(result).to include("ASCII text only")
    end
  end

  describe "error recovery" do
    it "returns appropriate error for unrecognized formats" do
      # Create a file with random binary data that's not a valid document
      corrupted_file = "spec/fixtures/corrupted.bin"
      FileUtils.mkdir_p("spec/fixtures")
      File.binwrite(corrupted_file, Random.bytes(100))
      
      # parser-core returns error for unrecognized file formats
      expect { ParserCore.parse_file(corrupted_file) }.to raise_error(RuntimeError, /Could not determine file type/)
      
      # Clean up temporary file
      File.delete(corrupted_file) if File.exist?(corrupted_file)
    end

    it "handles text files without errors" do
      text_file = "spec/fixtures/valid.txt"
      FileUtils.mkdir_p("spec/fixtures")
      File.write(text_file, "Valid text content")
      
      # Text files should parse successfully
      result = ParserCore.parse_file(text_file)
      expect(result).to include("Valid text content")
      
      # Clean up temporary file
      File.delete(text_file) if File.exist?(text_file)
    end
  end

  describe "configuration persistence" do
    it "maintains configuration across multiple parse operations" do
      parser = ParserCore::Parser.new(strict_mode: true, max_depth: 50)
      
      # Parse multiple times
      3.times do |i|
        parser.parse("test #{i}")
        
        # Configuration should remain unchanged
        expect(parser.strict_mode?).to be true
        expect(parser.config[:max_depth]).to eq(50)
      end
    end
  end

  describe "module and class methods consistency" do
    it "produces same results for module and instance methods" do
      input = "test content"
      
      # Module method
      module_result = ParserCore.parse(input)
      
      # Instance method
      parser = ParserCore::Parser.new
      instance_result = parser.parse(input)
      
      expect(module_result).to eq(instance_result)
    end

    it "handles file parsing consistently" do
      file = "spec/fixtures/consistency.txt"
      FileUtils.mkdir_p("spec/fixtures")
      File.write(file, "consistent content")
      
      # Module method
      module_result = ParserCore.parse_file(file)
      
      # Instance method
      parser = ParserCore::Parser.new
      instance_result = parser.parse_file(file)
      
      expect(module_result).to eq(instance_result)
      
      # Clean up temporary file
      File.delete(file) if File.exist?(file)
    end
  end
end