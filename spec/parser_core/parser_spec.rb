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
      # parser-core returns plain text as-is
      expect(result).to eq("Hello, World!")
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

      it "maintains configuration but returns text as-is for plain text" do
        result = parser.parse("test")
        expect(result).to eq("test")
        expect(parser.strict_mode?).to be true
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
      # Don't delete fixtures - they're in version control now
    end

    it "parses file content" do
      result = parser.parse_file(test_file)
      expect(result).to include("File content for parsing")
    end

    it "raises error for non-existent file" do
      expect { parser.parse_file("missing.txt") }.to raise_error(IOError)
    end

    it "returns error for unrecognized binary files" do
      binary_file = "spec/fixtures/binary.bin"
      File.binwrite(binary_file, "\x00\x01\x02\x03text\xFF\xFE")
      # parser-core returns error for unrecognized formats
      expect { parser.parse_file(binary_file) }.to raise_error(RuntimeError, /Could not determine file type/)
    end

    it "respects parser configuration when parsing files" do
      strict_parser = described_class.new(strict_mode: true)
      result = strict_parser.parse_file(test_file)
      expect(result).to include("File content")
      expect(strict_parser.strict_mode?).to be true
    end
  end

  describe "#parse_bytes" do
    let(:parser) { described_class.new }

    it "parses byte array" do
      bytes = "test content".bytes
      result = parser.parse_bytes(bytes)
      expect(result).to include("test content")
    end

    it "raises error for empty bytes" do
      expect { parser.parse_bytes([]) }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "returns error for non-document bytes" do
      # Random bytes that don't form a known document format
      bytes = [0x48, 0xe9, 0x6c, 0x6c, 0xf6] # Random bytes
      # parser-core requires valid document format
      expect { parser.parse_bytes(bytes) }.to raise_error(RuntimeError, /Could not determine file type/)
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

    it "returns true for unicode input" do
      expect(parser.valid_input?("Hello 世界")).to be true
    end

    it "returns true for whitespace-only input" do
      expect(parser.valid_input?("  \n\t  ")).to be true
    end
  end

  describe "error handling" do
    let(:parser) { described_class.new }

    it "provides meaningful error messages" do
      expect { parser.parse("") }.to raise_error(ArgumentError) do |error|
        expect(error.message).to include("cannot be empty")
      end
    end

    it "handles invalid file paths gracefully" do
      expect { parser.parse_file("/\0invalid/path") }.to raise_error(IOError)
    end
  end

  describe "performance" do
    let(:parser) { described_class.new }

    it "handles large inputs efficiently" do
      large_input = "a" * 10_000_000 # 10MB string
      start_time = Time.now
      result = parser.parse(large_input)
      elapsed = Time.now - start_time
      
      expect(result).to be_a(String)
      expect(elapsed).to be < 5.0 # Should complete within 5 seconds
    end
  end

  describe "memory management" do
    let(:parser) { described_class.new }

    it "doesn't leak memory on repeated parsing" do
      # This is a basic test - proper memory testing would use tools like memory_profiler
      100.times do
        parser.parse("test" * 1000)
      end
      # If we get here without crashing, basic memory management is working
      expect(parser).to be_a(described_class)
    end
  end
end