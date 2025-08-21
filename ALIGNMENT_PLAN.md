# Alignment Plan: no-parser-core Branch to Main Branch Interface

## Goal
Create an API that looks similar to the main branch but doesn't need 100% compatibility. Focus on matching the overall interface pattern while keeping the pure Rust, dependency-free implementation.

## Current State Analysis

### Main Branch (parser-core dependent)
- **Dependencies**: Uses the `parser-core` Rust crate directly
- **External Requirements**: Requires system libraries (Tesseract for OCR, etc.)
- **Core Function**: `parser_core::parse(&bytes)` - single unified parsing function

### no-parser-core Branch (self-contained)
- **Dependencies**: Pure Rust crates without system dependencies
  - `calamine` for Excel
  - `quick-xml` for XML/HTML
  - `serde_json` for JSON
  - `encoding_rs` for text encoding
  - `pdf-extract` (pure Rust with `default-features = false`)
- **Core Function**: Custom implementation with format detection
- **Advantages**: No external system dependencies required

## PDF Library Options

### Pure Rust PDF Libraries Comparison

| Library | Pros | Cons | Recommendation |
|---------|------|------|----------------|
| **pdf-extract** (current) | • Already integrated<br>• Simple API<br>• Pure Rust with `default-features = false`<br>• Active maintenance (v0.9.0 in 2025) | • Limited features without poppler<br>• Basic text extraction only | **Keep for now** - Working solution |
| **pdf-rs/pdf** | • Modern Rust approach<br>• Modular architecture<br>• Active development<br>• Pure Rust, no dependencies | • Still experimental for some features<br>• Would require migration | **Consider for future** |
| **lopdf** | • Most established<br>• Full PDF manipulation<br>• Very active maintenance<br>• Foundation for other libraries | • Lower-level API<br>• More manual work for text extraction | Use if need more control |
| **extractous** | • 25x faster than alternatives<br>• Multi-format support<br>• High performance<br>• OCR capabilities | • Larger footprint<br>• Overkill for simple PDF parsing | Use if performance critical |

### Decision
Stick with `pdf-extract` using `default-features = false` for pure Rust implementation. It's already working and actively maintained.

## API Differences

### 1. Method Naming
| Main Branch | no-parser-core Branch | Action Required |
|------------|---------------------|-----------------|
| `parse_bytes(data)` | `parse_data(data)` | Rename method to `parse_bytes` |
| N/A | `supports_file?(path)` | Keep (useful addition) |
| N/A | `supported_formats` | Keep (useful addition) |

### 2. Configuration Options
| Main Branch | no-parser-core Branch | Action Required |
|------------|---------------------|-----------------|
| `strict_mode` | N/A | Skip (not needed) |
| `max_depth` | N/A | Skip (not needed) |
| `encoding` | `encoding` | Already aligned ✓ |
| N/A | `max_size` | Keep (useful feature) |

### 3. Module-level Methods
| Main Branch | no-parser-core Branch | Action Required |
|------------|---------------------|-----------------|
| `ParserCore.parse_file` | `ParserCore.parse_file` | Already aligned ✓ |
| `ParserCore.parse_bytes` | `ParserCore.parse_data` | Rename to `parse_bytes` |
| `ParserCore.parse` | `ParserCore.parse` | Already aligned ✓ |

## Implementation Plan (Simplified)

### Phase 1: Method Alignment

#### 1.1 Rename parse_data to parse_bytes (parser.rs)
```rust
// Change method name for consistency with main branch
fn parse_bytes(&self, data: Vec<u8>) -> Result<String, Error>
```

#### 1.2 Update Module Registration (parser.rs)
```rust
// In init function
class.define_method("parse_bytes", method!(Parser::parse_bytes, 1))?;

// Module-level
module.define_singleton_method("parse_bytes", function!(parse_bytes_direct, 1))?;
```

### Phase 2: Ruby Interface Updates

#### 2.1 Update lib/parser_core.rb
```ruby
# Add parse_bytes convenience method
def parse_bytes(data, options = {})
  # Convert string to bytes if needed
  byte_data = data.is_a?(String) ? data.bytes : data
  Parser.new(options).parse_bytes(byte_data)
end
```

#### 2.2 Update lib/parser_core/parser.rb
- Update documentation to reflect `parse_bytes` instead of `parse_data`
- Keep the enhanced features (supports_file?, supported_formats)

### Phase 3: Enhanced PDF Support (Future)

#### 3.1 Current Solution
- Keep `pdf-extract` with `default-features = false`
- This provides pure Rust PDF text extraction without system dependencies

#### 3.2 Future Improvements
Consider migrating to one of these based on needs:
- **pdf-rs/pdf**: For more modern Rust approach
- **lopdf**: If need more control over PDF manipulation
- **extractous**: If performance becomes critical

### Phase 4: Testing

#### 4.1 Basic Compatibility Tests
```ruby
# spec/compatibility_spec.rb
RSpec.describe "API compatibility" do
  it "supports parse_bytes method" do
    parser = ParserCore::Parser.new
    expect(parser).to respond_to(:parse_bytes)
  end
  
  it "maintains parse_file interface" do
    parser = ParserCore::Parser.new
    expect(parser).to respond_to(:parse_file)
  end
end
```

### Phase 5: Feature Preservation

Keep these enhancements from no-parser-core:
1. `supports_file?` - Check file compatibility before parsing
2. `supported_formats` - List available parsers
3. `max_size` configuration - Prevent memory issues
4. Format-specific parsing - More control and transparency

## Migration Checklist

- [ ] Rename `parse_data` to `parse_bytes` in Rust code
- [ ] Update module registration for renamed methods
- [ ] Update Ruby wrapper to use `parse_bytes`
- [ ] Add parse_bytes module-level convenience method
- [ ] Update documentation and comments
- [ ] Ensure pdf-extract uses `default-features = false`
- [ ] Create basic compatibility tests
- [ ] Verify all tests pass

## Advantages of This Approach

1. **No External Dependencies**: Pure Rust implementation, no system libraries required
2. **Better Error Messages**: Format-specific error information
3. **More Control**: Check format support before parsing with `supports_file?`
4. **Extensible**: Easy to add new format parsers
5. **Transparent**: Users know which formats are supported via `supported_formats`
6. **Cross-platform**: Works everywhere Ruby and Rust work

## Current Limitations

1. **PDF Support**: Basic text extraction only (no OCR for image-based PDFs)
2. **Office Formats**: Primarily supports newer Office Open XML formats
3. **No OCR**: Cannot extract text from images

## Future Improvements

1. **Better PDF support**: Consider pdf-rs/pdf or extractous for enhanced capabilities
2. **Add more formats**: Could add support for RTF, Markdown, etc.
3. **Performance optimization**: Consider extractous if speed becomes critical
4. **OCR integration**: Could optionally add OCR support via feature flag

## Next Steps

1. Implement the simple rename from `parse_data` to `parse_bytes`
2. Update Ruby interface to match
3. Test the changes
4. Document the pure Rust nature as a feature in README