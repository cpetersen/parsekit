# frozen_string_literal: true

require_relative "lib/parsekit/version"

Gem::Specification.new do |spec|
  spec.name = "parsekit"
  spec.version = ParseKit::VERSION
  spec.authors = ["Chris Petersen"]
  spec.email = ["chris@petersen.io"]

  spec.summary = "Ruby document parsing toolkit with PDF and OCR support"
  spec.description = "Native Ruby gem for parsing documents (PDF, DOCX, XLSX, images with OCR) with zero runtime dependencies. Statically links MuPDF for PDF extraction and Tesseract for OCR."
  spec.homepage = "https://github.com/cpetersen/parsekit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*"] + Dir["ext/**/*.rs", "ext/**/*.toml", "ext/**/*.rb"] + 
    ["README.md", "LICENSE.txt", "CHANGELOG.md"].select { |f| File.exist?(f) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/parsekit/extconf.rb"]

  # Runtime dependencies
  spec.add_dependency "rb_sys", "~> 0.9"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.2"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end