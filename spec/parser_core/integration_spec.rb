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
    require 'tmpdir'
    
    it "can process multiple files sequentially" do
      Dir.mktmpdir do |dir|
        files = []
        3.times do |i|
          file = File.join(dir, "batch_#{i}.txt")
          File.write(file, "Content #{i}")
          files << file
        end

        results = files.map { |f| ParserCore.parse_file(f) }
        
        expect(results.size).to eq(3)
        expect(results).to all(be_a(String))
      end
    end
  end

  describe "encoding handling" do
    require 'tempfile'
    
    it "handles UTF-8 encoded files" do
      Tempfile.create(['utf8', '.txt']) do |file|
        file.write("UTF-8: 世界 мир विश्व")
        file.flush
        
        result = ParserCore.parse_file(file.path)
        expect(result).to include("UTF-8:")
      end
    end

    it "handles ASCII encoded files" do
      Tempfile.create(['ascii', '.txt'], encoding: 'ASCII') do |file|
        file.write("ASCII text only")
        file.flush
        
        result = ParserCore.parse_file(file.path)
        expect(result).to include("ASCII text only")
      end
    end
  end

  describe "error recovery" do
    require 'tempfile'
    
    it "returns appropriate error for unrecognized formats" do
      Tempfile.create(['corrupted', '.bin']) do |file|
        file.binmode
        file.write(Random.bytes(100))
        file.flush
        
        # parser-core returns error for unrecognized file formats
        expect { ParserCore.parse_file(file.path) }.to raise_error(RuntimeError, /Could not determine file type/)
      end
    end

    it "handles text files without errors" do
      Tempfile.create(['valid', '.txt']) do |file|
        file.write("Valid text content")
        file.flush
        
        # Text files should parse successfully
        result = ParserCore.parse_file(file.path)
        expect(result).to include("Valid text content")
      end
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
    require 'tempfile'
    
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
      Tempfile.create(['consistency', '.txt']) do |file|
        file.write("consistent content")
        file.flush
        
        # Module method
        module_result = ParserCore.parse_file(file.path)
        
        # Instance method
        parser = ParserCore::Parser.new
        instance_result = parser.parse_file(file.path)
        
        expect(module_result).to eq(instance_result)
      end
    end
  end
end