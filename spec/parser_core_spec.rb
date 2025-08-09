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
      FileUtils.rm_rf("spec/fixtures")
    end

    it "parses a file" do
      result = described_class.parse_file(test_file)
      expect(result).to be_a(String)
      expect(result).to include("test file content")
    end

    it "raises an error for non-existent file" do
      expect { described_class.parse_file("non_existent.txt") }.to raise_error(Errno::ENOENT)
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
      expect(ParserCore::Error).to be < StandardError
      expect(ParserCore::ParseError).to be < ParserCore::Error
      expect(ParserCore::ConfigError).to be < ParserCore::Error
    end
  end
end