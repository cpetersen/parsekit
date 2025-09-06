use std::path::Path;

/// Represents a detected file format
#[derive(Debug, Clone, PartialEq)]
pub enum FileFormat {
    Pdf,
    Docx,
    Xlsx,
    Xls,
    Pptx,
    Png,
    Jpeg,
    Tiff,
    Bmp,
    Json,
    Xml,
    Html,
    Text,
    Unknown,
}

impl FileFormat {
    /// Convert to Ruby symbol representation
    pub fn to_symbol(&self) -> &'static str {
        match self {
            FileFormat::Pdf => "pdf",
            FileFormat::Docx => "docx",
            FileFormat::Xlsx => "xlsx",
            FileFormat::Xls => "xls",
            FileFormat::Pptx => "pptx",
            FileFormat::Png => "png",
            FileFormat::Jpeg => "jpeg",
            FileFormat::Tiff => "tiff",
            FileFormat::Bmp => "bmp",
            FileFormat::Json => "json",
            FileFormat::Xml => "xml",
            FileFormat::Html => "xml", // HTML is treated as XML in Ruby
            FileFormat::Text => "text",
            FileFormat::Unknown => "unknown",
        }
    }
}

/// Central format detection logic
pub struct FormatDetector;

impl FormatDetector {
    /// Detect format from filename and content
    /// Prioritizes content detection over extension when both are available
    pub fn detect(filename: Option<&str>, content: Option<&[u8]>) -> FileFormat {
        // First try content-based detection if content is provided
        if let Some(data) = content {
            let format = Self::detect_from_content(data);
            // If we got a definitive format from content, use it
            if !matches!(format, FileFormat::Text | FileFormat::Unknown) {
                return format;
            }
        }
        
        // Fall back to extension-based detection
        if let Some(name) = filename {
            let ext_format = Self::detect_from_extension(name);
            if ext_format != FileFormat::Unknown {
                return ext_format;
            }
        }
        
        // If content detection returned Text and no extension match, return Text
        if let Some(data) = content {
            let format = Self::detect_from_content(data);
            if format == FileFormat::Text {
                return FileFormat::Text;
            }
        }
        
        FileFormat::Unknown
    }
    
    /// Detect format from file extension
    pub fn detect_from_extension(filename: &str) -> FileFormat {
        let path = Path::new(filename);
        let ext = match path.extension().and_then(|s| s.to_str()) {
            Some(e) => e.to_lowercase(),
            None => return FileFormat::Unknown,
        };
        
        match ext.as_str() {
            "pdf" => FileFormat::Pdf,
            "docx" => FileFormat::Docx,
            "xlsx" => FileFormat::Xlsx,
            "xls" => FileFormat::Xls,
            "pptx" => FileFormat::Pptx,
            "png" => FileFormat::Png,
            "jpg" | "jpeg" => FileFormat::Jpeg,
            "tiff" | "tif" => FileFormat::Tiff,
            "bmp" => FileFormat::Bmp,
            "json" => FileFormat::Json,
            "xml" => FileFormat::Xml,
            "html" | "htm" => FileFormat::Html,
            "txt" | "text" | "md" | "markdown" | "csv" => FileFormat::Text,
            _ => FileFormat::Unknown,
        }
    }
    
    /// Detect format from file content (magic bytes)
    pub fn detect_from_content(data: &[u8]) -> FileFormat {
        if data.is_empty() {
            return FileFormat::Text; // Empty files are treated as text
        }
        
        // PDF
        if data.len() >= 4 && data.starts_with(b"%PDF") {
            return FileFormat::Pdf;
        }
        
        // PNG
        if data.len() >= 8 && data.starts_with(&[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return FileFormat::Png;
        }
        
        // JPEG
        if data.len() >= 3 && data.starts_with(&[0xFF, 0xD8, 0xFF]) {
            return FileFormat::Jpeg;
        }
        
        // BMP
        if data.len() >= 2 && data.starts_with(b"BM") {
            return FileFormat::Bmp;
        }
        
        // TIFF (little-endian or big-endian)
        if data.len() >= 4 {
            if data.starts_with(b"II\x2A\x00") || data.starts_with(b"MM\x00\x2A") {
                return FileFormat::Tiff;
            }
        }
        
        // OLE Compound Document (old Excel/Word)
        if data.len() >= 4 && data.starts_with(&[0xD0, 0xCF, 0x11, 0xE0]) {
            return FileFormat::Xls; // Old Office format, usually Excel
        }
        
        // ZIP archive (could be DOCX, XLSX, PPTX)
        if data.len() >= 2 && data.starts_with(b"PK") {
            return Self::detect_office_format(data);
        }
        
        // XML
        if data.len() >= 5 {
            let start = String::from_utf8_lossy(&data[0..5.min(data.len())]);
            if start.starts_with("<?xml") || start.starts_with("<!") {
                return FileFormat::Xml;
            }
        }
        
        // HTML
        if data.len() >= 14 {
            let start = String::from_utf8_lossy(&data[0..14.min(data.len())]).to_lowercase();
            if start.contains("<!doctype") || start.contains("<html") {
                return FileFormat::Html;
            }
        }
        
        // JSON
        if let Some(&first_non_ws) = data.iter().find(|&&b| !b" \t\n\r".contains(&b)) {
            if first_non_ws == b'{' || first_non_ws == b'[' {
                return FileFormat::Json;
            }
        }
        
        // Default to text for unrecognized formats
        FileFormat::Text
    }
    
    /// Detect specific Office format from ZIP data
    fn detect_office_format(data: &[u8]) -> FileFormat {
        // Look for Office-specific directory names in first 2KB of ZIP
        let check_len = 2000.min(data.len());
        let content = String::from_utf8_lossy(&data[0..check_len]);
        
        // Check for format-specific markers
        if content.contains("word/") || content.contains("word/_rels") {
            FileFormat::Docx
        } else if content.contains("xl/") || content.contains("xl/_rels") {
            FileFormat::Xlsx
        } else if content.contains("ppt/") || content.contains("ppt/_rels") {
            FileFormat::Pptx
        } else {
            // Default to XLSX for generic ZIP (most common Office format)
            FileFormat::Xlsx
        }
    }
    
    
    /// Get all supported extensions
    pub fn supported_extensions() -> Vec<&'static str> {
        vec![
            "pdf", "docx", "xlsx", "xls", "pptx",
            "png", "jpg", "jpeg", "tiff", "tif", "bmp",
            "json", "xml", "html", "htm",
            "txt", "text", "md", "markdown", "csv"
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_detect_pdf() {
        let pdf_data = b"%PDF-1.5\n";
        assert_eq!(FormatDetector::detect_from_content(pdf_data), FileFormat::Pdf);
    }
    
    #[test]
    fn test_detect_png() {
        let png_data = &[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
        assert_eq!(FormatDetector::detect_from_content(png_data), FileFormat::Png);
    }
    
    #[test]
    fn test_detect_from_extension() {
        assert_eq!(FormatDetector::detect_from_extension("document.pdf"), FileFormat::Pdf);
        assert_eq!(FormatDetector::detect_from_extension("Document.PDF"), FileFormat::Pdf);
        assert_eq!(FormatDetector::detect_from_extension("data.xlsx"), FileFormat::Xlsx);
    }
    
    #[test]
    fn test_empty_data() {
        assert_eq!(FormatDetector::detect_from_content(&[]), FileFormat::Text);
    }
}