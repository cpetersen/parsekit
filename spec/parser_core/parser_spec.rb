# frozen_string_literal: true

RSpec.describe ParserCore::Parser do
  describe "#initialize" do
    it "creates a parser with default options" do
      parser = described_class.new
      expect(parser).to be_a(described_class)
      expect(parser.strict_mode?).to be false
    end

    it "creates a parser with custom options" do
      parser = described_class.new(strict_mode: true, max_depth: 50)
      expect(parser.strict_mode?).to be true
      config = parser.config
      expect(config[:max_depth]).to eq(50)
    end

    it "accepts encoding option" do
      parser = described_class.new(encoding: "ASCII")
      expect(parser.config[:encoding]).to eq("ASCII")
    end
  end

  describe "#parse" do
    let(:parser) { described_class.new }

    it "parses valid input" do
      result = parser.parse("Hello, World!")
      expect(result).to be_a(String)
      expect(result).to include("Hello, World!")
    end

    it "raises error for empty input" do
      expect { parser.parse("") }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "handles unicode input" do
      result = parser.parse("Hello 世界 🌍")
      expect(result).to include("Hello 世界 🌍")
    end

    context "with strict mode" do
      let(:parser) { described_class.new(strict_mode: true) }

      it "applies strict parsing rules" do
        result = parser.parse("test")
        expect(result).to include("strict=true")
      end
    end
  end

  describe "#parse_file" do
    let(:parser) { described_class.new }
    let(:test_file) { "spec/fixtures/parser_test.txt" }

    before do
      FileUtils.mkdir_p("spec/fixtures")
      File.write(test_file, "File content for parsing")
    end

    after do
      FileUtils.rm_rf("spec/fixtures")
    end

    it "parses file content" do
      result = parser.parse_file(test_file)
      expect(result).to include("File content for parsing")
    end

    it "raises error for non-existent file" do
      expect { parser.parse_file("missing.txt") }.to raise_error(IOError)
    end
  end

  describe "#config" do
    it "returns parser configuration as a hash" do
      parser = described_class.new(strict_mode: true, max_depth: 75)
      config = parser.config
      
      expect(config).to be_a(Hash)
      expect(config[:strict_mode]).to be true
      expect(config[:max_depth]).to eq(75)
      expect(config[:encoding]).to eq("UTF-8")
    end
  end

  describe "#strict_mode?" do
    it "returns false by default" do
      parser = described_class.new
      expect(parser.strict_mode?).to be false
    end

    it "returns true when strict mode is enabled" do
      parser = described_class.new(strict_mode: true)
      expect(parser.strict_mode?).to be true
    end
  end

  describe ".strict" do
    it "creates a parser with strict mode enabled" do
      parser = described_class.strict
      expect(parser.strict_mode?).to be true
    end

    it "merges additional options" do
      parser = described_class.strict(max_depth: 25)
      expect(parser.strict_mode?).to be true
      expect(parser.config[:max_depth]).to eq(25)
    end
  end

  describe "#parse_with_block" do
    let(:parser) { described_class.new }

    it "yields parsed result to block" do
      result = parser.parse_with_block("test") do |parsed|
        expect(parsed).to include("test")
        "modified: #{parsed}"
      end
      expect(result).to include("test")
    end

    it "returns result without block" do
      result = parser.parse_with_block("test")
      expect(result).to include("test")
    end
  end

  describe "#valid_input?" do
    let(:parser) { described_class.new }

    it "returns true for valid input" do
      expect(parser.valid_input?("valid")).to be true
    end

    it "returns false for nil input" do
      expect(parser.valid_input?(nil)).to be false
    end

    it "returns false for empty input" do
      expect(parser.valid_input?("")).to be false
    end
    
    it "returns false for non-string input" do
      expect(parser.valid_input?(123)).to be false
    end
  end

  describe "#parse_file_with_block" do
    let(:parser) { described_class.new }
    let(:test_file) { "spec/fixtures/test.txt" }

    before do
      FileUtils.mkdir_p("spec/fixtures")
      File.write(test_file, "test content")
    end

    after do
      FileUtils.rm_rf("spec/fixtures")
    end

    it "yields the parsed file content to the block" do
      block_called = false
      result = parser.parse_file_with_block(test_file) do |content|
        block_called = true
        expect(content).to include("test content")
        "processed: #{content}"
      end
      expect(block_called).to be true
      expect(result).to eq("test content")  # The method returns the parsed content, not the block's return value
    end

    it "returns the parsed content without a block" do
      result = parser.parse_file_with_block(test_file)
      expect(result).to eq("test content")
    end
  end

  describe "#valid_file?" do
    let(:parser) { described_class.new }

    context "with an existing supported file" do
      let(:test_file) { "spec/fixtures/test.txt" }

      before do
        FileUtils.mkdir_p("spec/fixtures")
        File.write(test_file, "content")
      end

      after do
        FileUtils.rm_rf("spec/fixtures")
      end

      it "returns true for existing supported file" do
        expect(parser.valid_file?(test_file)).to be true
      end
    end

    it "returns false for non-existent file" do
      expect(parser.valid_file?("non_existent.txt")).to be false
    end

    context "with an unsupported file" do
      let(:test_file) { "spec/fixtures/test.xyz" }

      before do
        FileUtils.mkdir_p("spec/fixtures")
        File.write(test_file, "content")
      end

      after do
        FileUtils.rm_rf("spec/fixtures")
      end

      it "returns false for unsupported file type" do
        expect(parser.valid_file?(test_file)).to be false
      end
    end
  end

  describe "#file_extension" do
    let(:parser) { described_class.new }

    it "returns the file extension in lowercase" do
      expect(parser.file_extension("test.TXT")).to eq("txt")
    end

    it "returns the extension for complex paths" do
      expect(parser.file_extension("/path/to/file.docx")).to eq("docx")
    end

    it "returns nil for files without extension" do
      expect(parser.file_extension("README")).to be_nil
    end

    it "handles multiple dots correctly" do
      expect(parser.file_extension("file.tar.gz")).to eq("gz")
    end
  end

  describe "#supports_file?" do
    let(:parser) { described_class.new }

    it "returns true for supported txt files" do
      expect(parser.supports_file?("test.txt")).to be true
    end

    it "returns true for supported docx files" do
      expect(parser.supports_file?("document.docx")).to be true
    end

    it "returns true for supported xlsx files" do
      expect(parser.supports_file?("spreadsheet.xlsx")).to be true
    end

    it "returns false for unsupported file types" do
      expect(parser.supports_file?("image.png")).to be false
    end

    it "handles uppercase extensions" do
      expect(parser.supports_file?("file.PDF")).to be true
    end
  end

  describe ".supported_formats" do
    it "returns an array of supported formats" do
      formats = described_class.supported_formats
      expect(formats).to be_an(Array)
      expect(formats).to include("txt", "docx", "xlsx", "json", "xml")
    end

    it "includes all expected formats" do
      formats = described_class.supported_formats
      %w[txt json xml html docx xlsx xls csv pdf].each do |format|
        expect(formats).to include(format)
      end
    end
  end
end