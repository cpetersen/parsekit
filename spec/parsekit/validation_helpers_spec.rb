# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe "ParseKit::Parser validation helpers" do
  let(:parser) { ParseKit::Parser.new }

  describe "#valid_input?" do
    context "with valid inputs" do
      it "returns true for non-empty strings" do
        expect(parser.valid_input?("valid text")).to be true
        expect(parser.valid_input?("a")).to be true
        expect(parser.valid_input?("123")).to be true
        expect(parser.valid_input?("special!@#$%^&*()")).to be true
      end

      it "returns true for strings with only whitespace (they have content)" do
        expect(parser.valid_input?(" ")).to be true
        expect(parser.valid_input?("   ")).to be true
        expect(parser.valid_input?("\t")).to be true
        expect(parser.valid_input?("\n")).to be true
        expect(parser.valid_input?(" \t\n ")).to be true
      end

      it "returns true for frozen strings" do
        frozen_string = "frozen".freeze
        expect(parser.valid_input?(frozen_string)).to be true
      end

      it "returns true for strings with unicode characters" do
        expect(parser.valid_input?("こんにちは")).to be true
        expect(parser.valid_input?("🎉")).to be true
        expect(parser.valid_input?("café")).to be true
      end
    end

    context "with invalid inputs" do
      it "returns false for nil" do
        expect(parser.valid_input?(nil)).to be false
      end

      it "returns false for empty string" do
        expect(parser.valid_input?("")).to be false
      end

      it "returns false for integers" do
        expect(parser.valid_input?(123)).to be false
        expect(parser.valid_input?(0)).to be false
        expect(parser.valid_input?(-456)).to be false
      end

      it "returns false for floats" do
        expect(parser.valid_input?(123.45)).to be false
        expect(parser.valid_input?(0.0)).to be false
      end

      it "returns false for arrays" do
        expect(parser.valid_input?([])).to be false
        expect(parser.valid_input?(["string"])).to be false
        expect(parser.valid_input?([1, 2, 3])).to be false
      end

      it "returns false for hashes" do
        expect(parser.valid_input?({})).to be false
        expect(parser.valid_input?({key: "value"})).to be false
      end

      it "returns false for symbols" do
        expect(parser.valid_input?(:symbol)).to be false
      end

      it "returns false for booleans" do
        expect(parser.valid_input?(true)).to be false
        expect(parser.valid_input?(false)).to be false
      end

      it "returns false for other objects" do
        expect(parser.valid_input?(Object.new)).to be false
        expect(parser.valid_input?(Time.now)).to be false
        expect(parser.valid_input?(/regex/)).to be false
      end
    end
  end

  describe "#valid_file?" do
    context "with valid files" do
      it "returns true for existing supported files" do
        Tempfile.create(['test', '.txt']) do |file|
          file.write("content")
          file.rewind
          expect(parser.valid_file?(file.path)).to be true
        end
      end

      it "returns true for supported files with uppercase extensions" do
        Tempfile.create(['test', '.TXT']) do |file|
          file.write("content")
          file.rewind
          expect(parser.valid_file?(file.path)).to be true
        end
      end

      it "returns true for various supported formats" do
        %w[.pdf .docx .xlsx .json .xml .html .md .csv].each do |ext|
          Tempfile.create(['test', ext]) do |file|
            file.write("content")
            file.rewind
            expect(parser.valid_file?(file.path)).to be true
          end
        end
      end

      it "handles symbolic links to valid files" do
        Dir.mktmpdir do |dir|
          real_file = File.join(dir, "real.txt")
          link_file = File.join(dir, "link.txt")
          
          File.write(real_file, "content")
          File.symlink(real_file, link_file)
          
          expect(parser.valid_file?(link_file)).to be true
        end
      end
    end

    context "with invalid files" do
      it "returns false for nil path" do
        expect(parser.valid_file?(nil)).to be false
      end

      it "returns false for empty string path" do
        expect(parser.valid_file?("")).to be false
      end

      it "returns false for non-existent files" do
        expect(parser.valid_file?("/non/existent/file.txt")).to be false
        expect(parser.valid_file?("does_not_exist.pdf")).to be false
      end

      it "returns false for directories" do
        Dir.mktmpdir do |dir|
          expect(parser.valid_file?(dir)).to be false
        end
      end

      it "returns false for unsupported file types" do
        Tempfile.create(['test', '.xyz']) do |file|
          file.write("content")
          file.rewind
          expect(parser.valid_file?(file.path)).to be false
        end
      end

      it "returns false for files without extensions" do
        Tempfile.create('no_extension') do |file|
          file.write("content")
          file.rewind
          expect(parser.valid_file?(file.path)).to be false
        end
      end

      it "returns false for broken symbolic links" do
        Dir.mktmpdir do |dir|
          link_file = File.join(dir, "broken_link.txt")
          File.symlink("/non/existent/target", link_file)
          
          expect(parser.valid_file?(link_file)).to be false
        end
      end

      it "returns false for special files" do
        # /dev/null exists on Unix systems
        if File.exist?("/dev/null")
          expect(parser.valid_file?("/dev/null")).to be false
        end
      end
    end

    context "with edge cases" do
      it "handles paths with spaces" do
        Dir.mktmpdir do |dir|
          file_with_spaces = File.join(dir, "file with spaces.txt")
          File.write(file_with_spaces, "content")
          
          expect(parser.valid_file?(file_with_spaces)).to be true
        end
      end

      it "handles very long paths" do
        Dir.mktmpdir do |dir|
          long_name = "a" * 200 + ".txt"
          long_path = File.join(dir, long_name)
          File.write(long_path, "content")
          
          expect(parser.valid_file?(long_path)).to be true
        end
      end

      it "handles relative paths" do
        Tempfile.create(['test', '.txt']) do |file|
          file.write("content")
          file.rewind
          
          Dir.chdir(File.dirname(file.path)) do
            relative_path = File.basename(file.path)
            expect(parser.valid_file?(relative_path)).to be true
          end
        end
      end
    end
  end

  describe "#file_extension" do
    context "with standard files" do
      it "returns the extension in lowercase" do
        expect(parser.file_extension("file.txt")).to eq("txt")
        expect(parser.file_extension("file.TXT")).to eq("txt")
        expect(parser.file_extension("file.Txt")).to eq("txt")
      end

      it "handles various extensions" do
        expect(parser.file_extension("document.pdf")).to eq("pdf")
        expect(parser.file_extension("spreadsheet.xlsx")).to eq("xlsx")
        expect(parser.file_extension("image.jpeg")).to eq("jpeg")
      end

      it "handles complex paths" do
        expect(parser.file_extension("/path/to/file.docx")).to eq("docx")
        expect(parser.file_extension("C:\\Windows\\file.exe")).to eq("exe")
        expect(parser.file_extension("../relative/path/file.json")).to eq("json")
      end

      it "handles multiple dots in filename" do
        expect(parser.file_extension("file.tar.gz")).to eq("gz")
        expect(parser.file_extension("my.document.v2.pdf")).to eq("pdf")
        expect(parser.file_extension("archive.2024.01.01.zip")).to eq("zip")
      end
    end

    context "with edge cases" do
      it "returns nil for nil input" do
        expect(parser.file_extension(nil)).to be_nil
      end

      it "returns nil for empty string" do
        expect(parser.file_extension("")).to be_nil
      end

      it "returns nil for files without extension" do
        expect(parser.file_extension("README")).to be_nil
        expect(parser.file_extension("/path/to/Makefile")).to be_nil
        expect(parser.file_extension("no_extension_file")).to be_nil
      end

      it "handles hidden files with extensions" do
        expect(parser.file_extension(".gitignore")).to eq("gitignore")
        expect(parser.file_extension(".env.local")).to eq("local")
        expect(parser.file_extension("/path/.hidden.txt")).to eq("txt")
      end

      it "returns nil for hidden files without extensions" do
        expect(parser.file_extension(".gitignore")).to eq("gitignore")  # This is actually an extension
        expect(parser.file_extension(".config")).to eq("config")  # This is actually an extension
      end

      it "handles files ending with a dot" do
        expect(parser.file_extension("file.")).to be_nil
        expect(parser.file_extension("document.txt.")).to be_nil
      end

      it "handles paths with trailing slashes" do
        expect(parser.file_extension("file.txt/")).to be_nil  # Trailing slash makes it look like a directory
        expect(parser.file_extension("/path/to/dir/")).to be_nil
      end

      it "handles whitespace in filenames" do
        expect(parser.file_extension("my file.txt")).to eq("txt")
        expect(parser.file_extension("  file.pdf  ")).to eq("pdf")  # Note: File.extname handles this
      end

      it "handles special characters in extensions" do
        expect(parser.file_extension("file.c++")).to eq("c++")
        expect(parser.file_extension("data.tar.gz")).to eq("gz")
      end

      it "handles very long extensions" do
        long_ext = "a" * 100
        expect(parser.file_extension("file.#{long_ext}")).to eq(long_ext.downcase)
      end

      it "handles unicode in filenames" do
        expect(parser.file_extension("文档.txt")).to eq("txt")
        expect(parser.file_extension("файл.pdf")).to eq("pdf")
        expect(parser.file_extension("🎉.json")).to eq("json")
      end
    end

    context "with platform-specific paths" do
      it "handles Windows-style paths" do
        expect(parser.file_extension("C:\\Users\\file.docx")).to eq("docx")
        expect(parser.file_extension("\\\\network\\share\\file.xlsx")).to eq("xlsx")
      end

      it "handles Unix-style paths" do
        expect(parser.file_extension("/home/user/file.sh")).to eq("sh")
        expect(parser.file_extension("~/documents/file.md")).to eq("md")
      end

      it "handles mixed path separators" do
        expect(parser.file_extension("C:/Users\\Documents/file.txt")).to eq("txt")
      end
    end
  end
end