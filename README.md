# ParseKit

ParseKit is a Ruby document parsing toolkit with zero runtime dependencies. It provides high-performance parsing for various document formats including PDF, DOCX, XLSX, and images with OCR support.

## Features

- **Zero Runtime Dependencies**: All libraries are statically linked - just `gem install` and go!
- **PDF Text Extraction**: Uses statically-linked MuPDF for reliable PDF parsing
- **OCR Support**: Embedded Tesseract for text extraction from images (PNG, JPEG, BMP, TIFF)
- **Office Documents**: Parse DOCX and XLSX files using pure Rust implementations
- **Multiple Formats**: Supports TXT, JSON, XML, HTML, CSV, and more
- **High Performance**: Native Rust implementation via Magnus FFI bindings
- **Cross-Platform**: Works on macOS, Linux, and Windows

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parsekit'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install parsekit

## Usage

### Basic Usage

```ruby
require 'parsekit'

# Create a parser instance
parser = ParseKit::Parser.new

# Parse various file types
pdf_text = parser.parse_file('document.pdf')
docx_text = parser.parse_file('document.docx')
xlsx_text = parser.parse_file('spreadsheet.xlsx')

# OCR images
image_text = parser.parse_file('scanned_document.png')

# Parse raw text
text = parser.parse("Hello, World!")
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
| Images | .png, .jpg, .jpeg, .tiff, .bmp | `ocr_image` | OCR via embedded Tesseract |
| JSON | .json | `parse_json` | Pretty-printed output |
| XML/HTML | .xml, .html | `parse_xml` | Extracts text content |
| Text | .txt, .csv, .md | `parse_text` | With encoding detection |

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

## Architecture

ParseKit uses a hybrid Ruby/Rust architecture:

- **Ruby Layer**: Provides convenient API and format detection
- **Rust Layer**: Implements high-performance parsing using:
  - MuPDF for PDF text extraction (statically linked)
  - rusty-tesseract for OCR (with embedded Tesseract)
  - Pure Rust libraries for DOCX/XLSX parsing
  - Magnus for Ruby-Rust FFI bindings

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cpetersen/parsekit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Note: This gem includes statically linked versions of MuPDF (AGPL/Commercial) and Tesseract (Apache 2.0). Please review their respective licenses for compliance with your use case.