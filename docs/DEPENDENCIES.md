# System Dependencies

The parsekit gem bundles all necessary libraries, making installation simple with no system dependencies required.

## Zero Dependencies by Default

As of version 0.2.0, ParseKit bundles:
- **Tesseract OCR**: Statically linked, no system installation needed
- **MuPDF**: Statically linked for PDF parsing

## Installation

Simply install the gem:

```bash
gem install parsekit
```

No additional system libraries are required!

## For Advanced Users: System Mode

If you already have Tesseract installed and want to use your system installation instead of the bundled version (for faster gem compilation during development), you can opt out of bundling:

### Using System Tesseract

Install system dependencies first:

#### macOS
```bash
brew install tesseract
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y libtesseract-dev tesseract-ocr
```

#### Fedora/RHEL/CentOS
```bash
sudo dnf install -y tesseract-devel tesseract
```

Then install the gem without bundled features:

```bash
gem install parsekit -- --no-default-features
```

For development:
```bash
rake compile CARGO_FEATURES=""  # Disables bundled-tesseract
```

## Docker

For containerized environments, here's a sample Dockerfile:

```dockerfile
FROM ruby:3.2

# Install Rust (required for compilation)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# No system dependencies needed with bundled mode!
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
```

## CI/CD

For GitHub Actions, no additional dependencies are needed:

```yaml
- name: Setup Ruby
  uses: ruby/setup-ruby@v1
  with:
    ruby-version: ruby
    bundler-cache: true

- name: Compile and test
  run: |
    bundle exec rake compile
    bundle exec rake spec
```

## Troubleshooting

### Compilation takes too long

The bundled mode compiles Tesseract from source, which can take 1-3 minutes on initial installation. This is a one-time cost. If you need faster rebuilds during development, consider using system mode.

### Out of memory during compilation

Bundling libraries requires more memory during compilation. If you encounter OOM errors:
1. Increase available memory
2. Or use system mode instead

### Want to use a specific Tesseract version

Use system mode and install your preferred Tesseract version through your package manager.