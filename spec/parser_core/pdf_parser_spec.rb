# frozen_string_literal: true

RSpec.describe "PDF Parsing with MuPDF" do
  let(:parser) { ParserCore::Parser.new }
  
  describe "#parse_pdf" do
    context "with valid PDF data" do
      let(:simple_pdf) do
        # Minimal valid PDF with "Hello World" text
        # This is a hand-crafted minimal PDF
        pdf_content = <<~PDF
          %PDF-1.4
          1 0 obj
          << /Type /Catalog /Pages 2 0 R >>
          endobj
          2 0 obj
          << /Type /Pages /Kids [3 0 R] /Count 1 >>
          endobj
          3 0 obj
          << /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >>
          endobj
          4 0 obj
          << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
          endobj
          5 0 obj
          << /Length 44 >>
          stream
          BT
          /F1 12 Tf
          100 700 Td
          (Hello World) Tj
          ET
          endstream
          endobj
          xref
          0 6
          0000000000 65535 f 
          0000000009 00000 n 
          0000000062 00000 n 
          0000000121 00000 n 
          0000000259 00000 n 
          0000000338 00000 n 
          trailer
          << /Size 6 /Root 1 0 R >>
          startxref
          435
          %%EOF
        PDF
        pdf_content.bytes
      end
      
      it "extracts text from PDF" do
        result = parser.parse_pdf(simple_pdf)
        expect(result).to be_a(String)
        expect(result).to include("Hello World")
      end
    end
    
    context "with empty PDF" do
      let(:empty_pdf) do
        # Minimal valid PDF structure without text content
        pdf_content = <<~PDF
          %PDF-1.4
          1 0 obj
          << /Type /Catalog /Pages 2 0 R >>
          endobj
          2 0 obj
          << /Type /Pages /Kids [] /Count 0 >>
          endobj
          xref
          0 3
          0000000000 65535 f 
          0000000009 00000 n 
          0000000062 00000 n 
          trailer
          << /Size 3 /Root 1 0 R >>
          startxref
          120
          %%EOF
        PDF
        pdf_content.bytes
      end
      
      it "returns appropriate message for PDF with no text" do
        result = parser.parse_pdf(empty_pdf)
        expect(result).to include("no extractable text")
      end
    end
    
    context "with invalid PDF data" do
      it "raises error for invalid PDF structure" do
        invalid_data = "Not a PDF file".bytes
        expect { parser.parse_pdf(invalid_data) }.to raise_error(RuntimeError, /Failed to parse PDF/)
      end
      
      it "raises error for corrupted PDF header" do
        corrupted_pdf = "%PDF-1.corrupted".bytes
        expect { parser.parse_pdf(corrupted_pdf) }.to raise_error(RuntimeError, /Failed to parse PDF/)
      end
    end
    
    context "with real PDF file" do
      let(:test_pdf_path) { "spec/fixtures/test.pdf" }
      
      before do
        FileUtils.mkdir_p("spec/fixtures")
        # Download a simple test PDF
        system("curl -s -o #{test_pdf_path} 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'")
      end
      
      after do
        FileUtils.rm_f(test_pdf_path) if File.exist?(test_pdf_path)
      end
      
      it "parses a real PDF file" do
        pdf_data = File.read(test_pdf_path, mode: 'rb').bytes
        result = parser.parse_pdf(pdf_data)
        expect(result).to be_a(String)
        expect(result).to include("Dummy PDF file")
      end
    end
  end
  
  describe "#parse_file with PDF" do
    let(:test_pdf_path) { "spec/fixtures/sample.pdf" }
    
    before do
      FileUtils.mkdir_p("spec/fixtures")
      # Create a minimal PDF file
      pdf_content = <<~PDF
        %PDF-1.4
        1 0 obj
        << /Type /Catalog /Pages 2 0 R >>
        endobj
        2 0 obj
        << /Type /Pages /Kids [3 0 R] /Count 1 >>
        endobj
        3 0 obj
        << /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >>
        endobj
        4 0 obj
        << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
        endobj
        5 0 obj
        << /Length 44 >>
        stream
        BT
        /F1 12 Tf
        100 700 Td
        (Test Content) Tj
        ET
        endstream
        endobj
        xref
        0 6
        0000000000 65535 f 
        0000000009 00000 n 
        0000000062 00000 n 
        0000000121 00000 n 
        0000000259 00000 n 
        0000000338 00000 n 
        trailer
        << /Size 6 /Root 1 0 R >>
        startxref
        435
        %%EOF
      PDF
      File.write(test_pdf_path, pdf_content)
    end
    
    after do
      FileUtils.rm_f(test_pdf_path) if File.exist?(test_pdf_path)
    end
    
    it "automatically detects and parses PDF files" do
      result = parser.parse_file(test_pdf_path)
      expect(result).to include("Test Content")
    end
  end
  
  describe "#parse_bytes with PDF auto-detection" do
    it "detects PDF from magic bytes and parses correctly" do
      pdf_content = <<~PDF
        %PDF-1.4
        1 0 obj
        << /Type /Catalog /Pages 2 0 R >>
        endobj
        2 0 obj
        << /Type /Pages /Kids [3 0 R] /Count 1 >>
        endobj
        3 0 obj
        << /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >>
        endobj
        4 0 obj
        << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
        endobj
        5 0 obj
        << /Length 50 >>
        stream
        BT
        /F1 12 Tf
        100 700 Td
        (Auto-detected PDF) Tj
        ET
        endstream
        endobj
        xref
        0 6
        0000000000 65535 f 
        0000000009 00000 n 
        0000000062 00000 n 
        0000000121 00000 n 
        0000000259 00000 n 
        0000000338 00000 n 
        trailer
        << /Size 6 /Root 1 0 R >>
        startxref
        441
        %%EOF
      PDF
      
      result = parser.parse_bytes(pdf_content.bytes)
      expect(result).to include("Auto-detected PDF")
    end
  end
  
  describe "PDF support verification" do
    it "includes pdf in supported formats" do
      formats = ParserCore::Parser.supported_formats
      expect(formats).to include("pdf")
    end
    
    it "recognizes .pdf files as supported" do
      expect(parser.supports_file?("document.pdf")).to be true
      expect(parser.supports_file?("DOCUMENT.PDF")).to be true
    end
  end
  
  describe "Performance and size limits" do
    let(:parser_with_limit) { ParserCore::Parser.new(max_size: 100) } # 100 bytes limit
    
    it "respects max_size configuration" do
      # Create a valid but large PDF that exceeds the size limit
      large_pdf = <<~PDF
        %PDF-1.4
        1 0 obj
        << /Type /Catalog /Pages 2 0 R >>
        endobj
        2 0 obj
        << /Type /Pages /Kids [3 0 R] /Count 1 >>
        endobj
        3 0 obj
        << /Type /Page /Parent 2 0 R /Resources << >> /MediaBox [0 0 612 792] >>
        endobj
        xref
        0 4
        0000000000 65535 f 
        0000000009 00000 n 
        0000000062 00000 n 
        0000000121 00000 n 
        trailer
        << /Size 4 /Root 1 0 R >>
        startxref
        250
        %%EOF
      PDF
      
      # Since parse_pdf is called directly, it bypasses the size check in parse_bytes_internal
      # We need to test through parse_bytes which includes the size check
      expect { parser_with_limit.parse_bytes(large_pdf.bytes) }.to raise_error(RuntimeError, /exceeds maximum/)
    end
  end
  
  describe "MuPDF static linking verification" do
    it "does not require external PDF libraries at runtime" do
      # This test verifies that the gem works without poppler/tesseract
      # by successfully parsing a PDF
      pdf_data = "%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\nxref\n0 2\n0000000000 65535 f \n0000000009 00000 n \ntrailer\n<< /Size 2 /Root 1 0 R >>\nstartxref\n64\n%%EOF".bytes
      
      # This should work even without poppler installed
      expect { parser.parse_pdf(pdf_data) }.not_to raise_error
    end
  end
end