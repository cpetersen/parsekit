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
  end
end