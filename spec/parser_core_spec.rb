# frozen_string_literal: true

RSpec.describe ParserCore do
  it "has a version number" do
    expect(ParserCore::VERSION).not_to be_nil
    expect(ParserCore::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  describe ".parse" do
    it "parses a simple string" do
      result = described_class.parse("test input")
      expect(result).to be_a(String)
      expect(result).to include("test input")
    end

    it "accepts options" do
      result = described_class.parse("test", strict_mode: true)
      expect(result).to be_a(String)
    end

    it "raises an error for nil input" do
      expect { described_class.parse(nil) }.to raise_error(TypeError)
    end

    it "raises an error for empty input" do
      expect { described_class.parse("") }.to raise_error(ArgumentError)
    end
  end

  describe ".parse_file" do
    let(:test_file) { "spec/fixtures/test.txt" }

    before do
      FileUtils.mkdir_p("spec/fixtures")
      File.write(test_file, "test file content")
    end

    after do
      # Clean up only temporary test files, not the sample documents
      File.delete("spec/fixtures/test.txt") if File.exist?("spec/fixtures/test.txt")
      File.delete("spec/fixtures/unicode.txt") if File.exist?("spec/fixtures/unicode.txt")
      File.delete("spec/fixtures/empty.txt") if File.exist?("spec/fixtures/empty.txt")
    end

    it "parses a file" do
      result = described_class.parse_file(test_file)
      expect(result).to be_a(String)
      expect(result).to include("test file content")
    end

    it "raises an error for non-existent file" do
      expect { described_class.parse_file("non_existent.txt") }.to raise_error(IOError)
    end

    it "handles files with unicode content" do
      unicode_file = "spec/fixtures/unicode.txt"
      File.write(unicode_file, "Hello 世界 🌍 Здравствуй мир")
      result = described_class.parse_file(unicode_file)
      expect(result).to include("Hello 世界 🌍")
    end

    it "handles empty files" do
      empty_file = "spec/fixtures/empty.txt"
      File.write(empty_file, "")
      # parser-core returns empty string for empty files
      result = described_class.parse_file(empty_file)
      expect(result).to eq("")
    end
  end

  describe ".parse_bytes" do
    it "parses binary data" do
      data = "test content".bytes
      result = described_class.parse_bytes(data)
      expect(result).to be_a(String)
      expect(result).to include("test content")
    end

    it "raises an error for empty data" do
      expect { described_class.parse_bytes([]) }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "handles unicode binary data" do
      unicode_text = "Hello 世界 🌍"
      data = unicode_text.bytes
      result = described_class.parse_bytes(data)
      expect(result).to include(unicode_text)
    end

    it "handles large binary data" do
      # Create 1MB of text data
      large_text = "a" * (1024 * 1024)
      data = large_text.bytes
      result = described_class.parse_bytes(data)
      expect(result.length).to be > 0
    end
  end

  describe ".native_version" do
    it "returns the native library version" do
      version = described_class.native_version
      expect(version).to be_a(String)
      expect(version).not_to eq("unknown")
    end
  end

  describe "error classes" do
    it "defines custom error classes" do
      # Error classes are defined in the native extension
      # They don't inherit from StandardError in the current implementation
      expect(ParserCore::Error).to be_a(Class)
      expect(ParserCore::ParseError).to be_a(Class)
      expect(ParserCore::ConfigError).to be_a(Class)
    end
  end

  describe "edge cases" do
    it "handles very long strings" do
      long_string = "x" * 1_000_000
      result = described_class.parse(long_string)
      expect(result).to be_a(String)
    end

    it "handles strings with null bytes" do
      string_with_null = "test\0content"
      result = described_class.parse(string_with_null)
      expect(result).to be_a(String)
    end

    it "handles strings with only whitespace" do
      result = described_class.parse("   \n\t  ")
      expect(result).to be_a(String)
    end

    it "handles strings with special characters" do
      special_chars = "!@#$%^&*()_+-=[]{}|;':,.<>?/~`"
      result = described_class.parse(special_chars)
      expect(result).to include(special_chars)
    end
  end

  describe "thread safety" do
    it "can parse concurrently from multiple threads" do
      results = []
      threads = 10.times.map do |i|
        Thread.new do
          result = described_class.parse("thread #{i}")
          results << result
        end
      end
      threads.each(&:join)
      
      expect(results.size).to eq(10)
      expect(results).to all(be_a(String))
    end
  end
end