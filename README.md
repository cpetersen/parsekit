<img src="/docs/assets/parsekit-wide.png" alt="parsekit" height="80px">

[![Gem Version](https://badge.fury.io/rb/parsekit.svg)](https://badge.fury.io/rb/parsekit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Native Ruby bindings for the [parser-core](https://crates.io/crates/parser-core) Rust crate, providing high-performance document parsing and text extraction capabilities through Magnus. This gem wraps parser-core to extract text from PDFs, Office documents (DOCX, XLSX), images (with OCR), and more. Part of the ruby-nlp ecosystem.

## Features

- 📄 **Document Parsing**: Extract text from PDFs, Office documents (DOCX, XLSX)
- 🖼️ **OCR Support**: Extract text from images using Tesseract OCR
- 🚀 **High Performance**: Native Rust performance with Ruby convenience
- 🔧 **Unified API**: Single interface for multiple document formats
- 📦 **Cross-Platform**: Works on Linux, macOS, and Windows
- 🧪 **Well Tested**: Comprehensive test suite with RSpec

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parsekit'
```

And then execute:

    $ bundle install

Or install it yourself as:

```bash
gem install parsekit
```

### Requirements

- Ruby >= 3.0.0
- Rust toolchain (stable)
- C compiler (for linking)

That's it! ParseKit bundles all necessary libraries including Tesseract for OCR, so you don't need to install any system dependencies.

## Usage

### Basic Usage

```ruby
require 'parsekit'

# Parse a PDF file
text = ParseKit.parse_file("document.pdf")
puts text  # Extracted text from the PDF

# Parse an Excel file
text = ParseKit.parse_file("spreadsheet.xlsx")
puts text  # Extracted text from all sheets

# Parse binary data directly
file_data = File.binread("document.pdf")
text = ParseKit.parse_bytes(file_data)
puts text

# Parse with a Parser instance
parser = ParseKit::Parser.new
text = parser.parse_file("report.docx")
puts text
```

### Module-Level Convenience Methods

```ruby
# Parse files directly
content = ParseKit.parse_file('document.pdf')

# Parse bytes
data = File.read('document.pdf', mode: 'rb')
content = ParseKit.parse_bytes(data.bytes)

# Check supported formats
formats = ParseKit.supported_formats
# => ["txt", "json", "xml", "html", "docx", "xlsx", "xls", "csv", "pdf", "png", "jpg", "jpeg", "tiff", "bmp"]

# Check if a file is supported
ParseKit.supports_file?('document.pdf')  # => true
```

### Configuration Options

```ruby
# Create parser with options
parser = ParseKit::Parser.new(
  strict_mode: true,
  max_size: 50 * 1024 * 1024,  # 50MB limit
  encoding: 'UTF-8'
)

# Or use the strict convenience method
parser = ParseKit::Parser.strict
```

### Format-Specific Parsing

```ruby
parser = ParseKit::Parser.new

# Direct access to format-specific parsers
pdf_data = File.read('document.pdf', mode: 'rb').bytes
pdf_text = parser.parse_pdf(pdf_data)

image_data = File.read('image.png', mode: 'rb').bytes
ocr_text = parser.ocr_image(image_data)

excel_data = File.read('data.xlsx', mode: 'rb').bytes
excel_text = parser.parse_xlsx(excel_data)
```

## Supported Formats

| Format | Extensions | Method | Notes |
|--------|------------|--------|-------|
| PDF | .pdf | `parse_pdf` | Text extraction via MuPDF |
| Word | .docx | `parse_docx` | Office Open XML format |
| Excel | .xlsx, .xls | `parse_xlsx` | Both modern and legacy formats |
| PowerPoint | .pptx | - | **Not yet supported** - see [implementation plan](docs/PPTX_PLAN.md) |
| Images | .png, .jpg, .jpeg, .tiff, .bmp | `ocr_image` | OCR via bundled Tesseract |
| JSON | .json | `parse_json` | Pretty-printed output |
| XML/HTML | .xml, .html | `parse_xml` | Extracts text content |
| Text | .txt, .csv, .md | `parse_text` | With encoding detection |

### Note on PowerPoint Support

While PPTX files are listed in our features, they are not yet fully implemented. Currently, PPTX files will return binary data instead of extracted text. We have a detailed [implementation plan](docs/PPTX_PLAN.md) for adding proper PPTX support in a future release. This will involve:
- Adding ZIP archive handling capabilities
- Implementing XML extraction from PowerPoint slide files
- Following the same Office Open XML approach used for DOCX files

For now, if you need to extract text from PowerPoint files, we recommend converting them to PDF first.

## Performance

ParseKit is built with performance in mind:

- Native Rust implementation for speed
- Statically linked C libraries (MuPDF, Tesseract) compiled with optimizations
- Efficient memory usage with streaming where possible
- Configurable size limits to prevent memory issues

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To compile the Rust extension:

```bash
rake compile
```

To run tests with coverage:

```bash
rake dev:coverage
```

### OCR Mode Configuration

By default, ParseKit bundles Tesseract for zero-dependency OCR support. Advanced users who already have Tesseract installed system-wide and want faster gem installation can use system mode:

**Using system Tesseract during installation:**
```bash
gem install parsekit -- --no-default-features
```

**For development with system Tesseract:**
```bash
rake compile CARGO_FEATURES=""  # Disables bundled-tesseract feature
```

**System Tesseract requirements:**
- **macOS**: `brew install tesseract`
- **Ubuntu/Debian**: `sudo apt-get install libtesseract-dev`
- **Fedora/RHEL**: `sudo dnf install tesseract-devel`

The bundled mode adds ~1-3 minutes to initial gem installation but provides a completely self-contained experience with no external dependencies.

## Architecture

ParseKit uses a hybrid Ruby/Rust architecture:

- **Ruby Layer**: Provides convenient API and format detection
- **Rust Layer**: Implements high-performance parsing using:
  - MuPDF for PDF text extraction (statically linked)
  - tesseract-rs for OCR (with bundled Tesseract by default)
  - Pure Rust libraries for DOCX/XLSX parsing
  - Magnus for Ruby-Rust FFI bindings

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cpetersen/parsekit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Note: This gem includes statically linked versions of MuPDF (AGPL/Commercial) and Tesseract (Apache 2.0). Please review their respective licenses for compliance with your use case.
