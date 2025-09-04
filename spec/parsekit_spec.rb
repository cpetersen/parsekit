# frozen_string_literal: true

RSpec.describe ParseKit do
  it "has a version number" do
    expect(ParseKit::VERSION).not_to be_nil
    expect(ParseKit::VERSION).to match(/\d+\.\d+\.\d+/)
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
      FileUtils.rm_f(test_file) if File.exist?(test_file)
    end

    it "parses a file" do
      result = described_class.parse_file(test_file)
      expect(result).to be_a(String)
      expect(result).to include("test file content")
    end

    it "raises an error for non-existent file" do
      expect { described_class.parse_file("non_existent.txt") }.to raise_error(IOError)
    end
  end

  describe ".parse_bytes" do
    it "parses binary data from a string" do
      result = described_class.parse_bytes("test data")
      expect(result).to be_a(String)
      expect(result).to include("test data")
    end

    it "parses binary data from an array of bytes" do
      bytes = "test".bytes
      result = described_class.parse_bytes(bytes)
      expect(result).to be_a(String)
      expect(result).to include("test")
    end

    it "accepts options" do
      result = described_class.parse_bytes("test", encoding: "UTF-8")
      expect(result).to be_a(String)
    end
  end

  describe ".supported_formats" do
    it "returns an array of supported file formats" do
      formats = described_class.supported_formats
      expect(formats).to be_an(Array)
      expect(formats).not_to be_empty
    end

    it "includes common formats" do
      formats = described_class.supported_formats
      %w[txt docx xlsx json xml].each do |format|
        expect(formats).to include(format)
      end
    end
  end

  describe ".supports_file?" do
    it "returns true for supported file types" do
      expect(described_class.supports_file?("test.txt")).to be true
      expect(described_class.supports_file?("document.docx")).to be true
    end

    it "returns false for unsupported file types" do
      expect(described_class.supports_file?("audio.mp3")).to be false
      expect(described_class.supports_file?("video.mp4")).to be false
    end

    it "handles uppercase extensions" do
      expect(described_class.supports_file?("FILE.TXT")).to be true
    end
  end

  describe ".native_version" do
    it "returns the native library version" do
      version = described_class.native_version
      expect(version).to be_a(String)
      expect(version).not_to eq("unknown")
    end
  end

  describe "markdown file parsing" do
    let(:md_file) { "spec/fixtures/sample.md" }

    it "parses markdown files" do
      result = described_class.parse_file(md_file)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it "extracts text content from markdown" do
      result = described_class.parse_file(md_file)
      # Note: parsekit currently treats .md files as plain text, so markdown formatting is preserved
      expect(result).to include("Markdown document for testing")
      expect(result).to include("**Bold text**")
      expect(result).to include("*Italic text*")
    end

    it "handles Unicode content" do
      result = described_class.parse_file(md_file)
      expect(result).to include("Hello 世界 🌍")
    end

    it "processes markdown tables as plain text" do
      result = described_class.parse_file(md_file)
      expect(result).to include("Header 1")
      expect(result).to include("Header 2")
      expect(result).to include("Row 1")
      # Note: The actual content has "Row 1" twice in the test data
    end

    it "includes bullet points" do
      result = described_class.parse_file(md_file)
      expect(result).to include("Bullet points")
    end
  end

  describe "HTML file parsing" do
    let(:html_file) { "spec/fixtures/sample.html" }

    it "parses HTML files" do
      result = described_class.parse_file(html_file)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it "extracts text content from HTML" do
      result = described_class.parse_file(html_file)
      expect(result).to include("Welcome to the HTML Document")
      expect(result).to include("HTML document for testing")
      expect(result).to include("Bold text")
      expect(result).to include("Italic text")
    end

    it "handles HTML table content" do
      result = described_class.parse_file(html_file)
      expect(result).to include("Header 1")
      expect(result).to include("Header 2")
      expect(result).to include("Row 1")
      expect(result).to include("Row 2")
      expect(result).to include("Data 1")
      expect(result).to include("Data 2")
    end

    it "processes HTML lists" do
      result = described_class.parse_file(html_file)
      expect(result).to include("Bullet points")
    end

    it "handles Unicode content" do
      result = described_class.parse_file(html_file)
      expect(result).to include("Hello 世界 🌍")
    end

    it "processes links" do
      result = described_class.parse_file(html_file)
      expect(result).to include("Link")
    end

    it "extracts page title" do
      result = described_class.parse_file(html_file)
      expect(result).to include("Sample HTML Document")
    end

    it "should not include HTML tags in output" do
      result = described_class.parse_file(html_file)
      expect(result).not_to include("<html>")
      expect(result).not_to include("<head>")
      expect(result).not_to include("<body>")
      expect(result).not_to include("<h1>")
      expect(result).not_to include("<p>")
      expect(result).not_to include("<strong>")
      expect(result).not_to include("<em>")
    end
  end

  describe "file type detection" do
    it "correctly identifies markdown files" do
      expect(described_class.supports_file?("document.md")).to be true
      expect(described_class.supports_file?("README.MD")).to be true
    end

    it "correctly identifies HTML files" do
      expect(described_class.supports_file?("page.html")).to be true
      expect(described_class.supports_file?("index.HTM")).to be true
    end
  end

  describe "error classes" do
    it "defines custom error classes" do
      # Error classes are defined in the native extension
      # They don't inherit from StandardError in the current implementation
      expect(ParseKit::Error).to be_a(Class)
      expect(ParseKit::ParseError).to be_a(Class)
      expect(ParseKit::ConfigError).to be_a(Class)
    end
  end
end
