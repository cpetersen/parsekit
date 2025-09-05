# Refactoring Plan: Separate Routing from Parsing

## Current Architecture Problems

1. **Rust is doing too much**: File type detection, routing, AND parsing
2. **Hard to test**: Can't test individual parsers from Ruby
3. **Complex Rust code**: The `parse_bytes_internal` method is doing routing that could be simpler
4. **Opaque to Ruby**: Ruby doesn't know what parser is being used

## Proposed Architecture

### Ruby Layer (Router/Orchestrator)
```ruby
module ParseKit
  class Parser
    # High-level parse method that routes to specific parsers
    def parse_file(path)
      format = detect_format(path)
      data = File.read(path, mode: 'rb')
      
      case format
      when :docx then parse_docx_internal(data)
      when :xlsx then parse_xlsx_internal(data)
      when :pdf  then parse_pdf_internal(data)
      when :json then parse_json_internal(data)
      when :xml  then parse_xml_internal(data)
      else parse_text_internal(data)
      end
    end
    
    # Ruby detects the format
    def detect_format(path)
      ext = File.extname(path).downcase[1..]
      return nil unless ext
      
      case ext
      when 'docx' then :docx
      when 'xlsx', 'xls' then :xlsx
      when 'pdf' then :pdf
      when 'json' then :json
      when 'xml', 'html' then :xml
      else :text
      end
    end
    
    # Or detect from content
    def detect_format_from_bytes(data)
      # Check magic bytes
      return :pdf if data.start_with?("%PDF")
      return :xlsx if data.start_with?("PK")
      # etc...
    end
    
    private
    
    # These call specific Rust methods
    def parse_docx_internal(data)
      # Calls Rust parse_docx directly
    end
    
    def parse_xlsx_internal(data)
      # Calls Rust parse_xlsx directly
    end
  end
end
```

### Rust Layer (Pure Parsers)
```rust
impl Parser {
    /// Parse DOCX file - no routing, just parsing
    fn parse_docx(&self, data: Vec<u8>) -> Result<String, Error> {
        // Just parse DOCX, no format detection
        use docx_rs::read_docx;
        match read_docx(&data) {
            // ... actual parsing logic
        }
    }
    
    /// Parse Excel file - no routing, just parsing
    fn parse_xlsx(&self, data: Vec<u8>) -> Result<String, Error> {
        use calamine::{Reader, Xlsx};
        // ... actual parsing logic
    }
    
    /// Parse JSON - no routing, just parsing
    fn parse_json(&self, data: Vec<u8>) -> Result<String, Error> {
        let text = String::from_utf8_lossy(&data);
        // ... actual parsing logic
    }
    
    // No more parse_bytes_internal with routing!
}
```

## Benefits

1. **Simpler Rust code**: Each function does one thing
2. **Better testability**: Can test each parser individually from Ruby
3. **More transparent**: Ruby knows exactly what parser is being used
4. **Easier to extend**: Add new formats by adding a parser and updating Ruby routing
5. **Better error messages**: Ruby can provide format-specific error context
6. **Format-specific options**: Easy to pass format-specific options to individual parsers

## Implementation Steps

### Phase 1: Expose Individual Parsers
1. Keep existing `parse_bytes_internal` for backward compatibility
2. Add individual parser methods in Rust:
   - `parse_docx`
   - `parse_xlsx`
   - `parse_json`
   - `parse_xml`
   - `parse_text`
   - `parse_pdf`
3. Register these methods with Magnus

### Phase 2: Ruby Routing
1. Implement `detect_format` in Ruby
2. Implement `detect_format_from_bytes` in Ruby (can call Rust helper if needed)
3. Update `parse_file` to use Ruby routing
4. Update `parse_bytes` to use Ruby routing

### Phase 3: Testing
1. Add tests for each individual parser
2. Test format detection separately
3. Test routing logic separately
4. Better coverage visibility

### Phase 4: Cleanup
1. Remove routing logic from Rust
2. Simplify Rust code
3. Document the new architecture

## Example Usage After Refactoring

```ruby
parser = ParseKit::Parser.new

# High-level API (unchanged)
parser.parse_file("document.docx")  # Ruby detects format and routes

# New: Can also call specific parsers directly
parser.parse_docx(docx_data)        # Direct DOCX parsing
parser.parse_xlsx(excel_data)       # Direct Excel parsing

# Testing becomes easier
describe "#parse_docx" do
  it "parses DOCX content" do
    data = File.read("test.docx", mode: "rb")
    result = parser.parse_docx(data)
    expect(result).to include("expected text")
  end
end

# Can test routing separately
describe "#detect_format" do
  it "detects DOCX files" do
    expect(parser.detect_format("test.docx")).to eq(:docx)
  end
end
```

## Migration Strategy

1. **Add new methods first** - Don't break existing code
2. **Parallel implementation** - New routing alongside old
3. **Gradual migration** - Update tests and callers gradually
4. **Remove old code** - Once everything is migrated

## Questions to Consider

1. Should format detection be in Ruby or Rust?
   - **Recommendation**: Ruby for file extensions, optional Rust helper for magic bytes

2. Should we expose individual parsers to end users?
   - **Recommendation**: Yes, but document that `parse_file` is preferred

3. How to handle format-specific options?
   - **Recommendation**: Each parser can have its own options hash

4. Error handling?
   - **Recommendation**: Format-specific error classes in Ruby

## Conclusion

This refactoring will:
- Make the codebase more maintainable
- Improve testability significantly  
- Make it clearer what's happening at each layer
- Allow for format-specific optimizations and options
- Make it easier to add new formats