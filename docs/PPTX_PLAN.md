# PPTX Parsing Implementation Plan

## Problem Summary
PPTX files are not being parsed correctly - they return raw binary data instead of extracted text. The issue stems from:

1. **Ruby Layer**: The `detect_format` method in `lib/parsekit/parser.rb` doesn't recognize `.pptx` extension
2. **Rust Layer**: No PPTX parsing implementation exists in `ext/parsekit/src/parser.rs`
3. **File Detection**: When PPTX files are detected as ZIP archives (PK signature), they incorrectly fall back to DOCX parsing

## Solution Approach

Since PPTX is an Office Open XML format (like DOCX/XLSX), we have two options:

### Option 1: Manual XML Extraction (Simpler, No New Dependencies)
- PPTX files are ZIP archives containing XML files
- We can use existing `quick-xml` dependency to parse the slide XML files
- Extract text from `ppt/slides/slide*.xml` files

### Option 2: Use a Dedicated PPTX Library
- Look for a Rust crate that handles PPTX parsing
- After research, there's no mature PPTX parsing crate like `docx-rs` for PowerPoint

## Recommended Implementation (Option 1)

### Step 1: Update Ruby Layer
In `lib/parsekit/parser.rb`:
- Add 'pptx' case to `detect_format` method (line ~95)
- Add 'pptx' to the routed parsing methods

### Step 2: Update Rust Layer
In `ext/parsekit/src/parser.rs`:
1. Update `detect_type_from_filename` to recognize 'pptx'
2. Add logic to distinguish PPTX from DOCX in ZIP detection
3. Implement `parse_pptx` method that:
   - Unzips the PPTX file using `zip` crate (need to add dependency)
   - Reads slide XML files from `ppt/slides/`
   - Extracts text content from XML using `quick-xml`
   - Combines text from all slides

### Step 3: Add Dependencies
In `ext/parsekit/Cargo.toml`:
- Add `zip = "2.1"` for handling ZIP archives

### Step 4: Implementation Details

```rust
fn parse_pptx(&self, data: Vec<u8>) -> Result<String, Error> {
    use std::io::Cursor;
    use zip::ZipArchive;
    
    let cursor = Cursor::new(data);
    let mut archive = ZipArchive::new(cursor)?;
    let mut all_text = String::new();
    
    // Iterate through slides
    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        let name = file.name();
        
        // Process slide XML files
        if name.starts_with("ppt/slides/slide") && name.ends_with(".xml") {
            let mut contents = String::new();
            file.read_to_string(&mut contents)?;
            
            // Extract text from XML
            let text = extract_text_from_slide_xml(&contents);
            all_text.push_str(&text);
            all_text.push_str("\n\n");
        }
    }
    
    Ok(all_text.trim().to_string())
}
```

### Step 5: Testing
- Verify the existing PPTX fixture file contains readable text
- Update the integration spec to check for actual text content once implementation is complete

## Implementation Priority
1. Add zip dependency
2. Implement basic PPTX parsing in Rust
3. Update Ruby layer to route PPTX files correctly
4. Test with sample.pptx
5. Update specs with proper assertions

## Expected Outcome
After implementation, PPTX files should extract:
- Text from all slides
- Title and body text
- Text from text boxes and shapes
- Notes (optional, in `ppt/notesSlides/`)