# System Dependencies

The parsekit gem wraps the [parser-core](https://crates.io/crates/parser-core) Rust crate, which requires several system libraries for document parsing and OCR functionality.

## Required Libraries

### macOS

Install using Homebrew:

```bash
brew install leptonica tesseract poppler
```

If you encounter pkg-config issues:
```bash
brew install pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y \
  libleptonica-dev \
  libtesseract-dev \
  libpoppler-cpp-dev \
  tesseract-ocr \
  pkg-config
```

### Fedora/RHEL/CentOS

```bash
sudo dnf install -y \
  leptonica-devel \
  tesseract-devel \
  poppler-cpp-devel \
  tesseract \
  pkg-config
```

### Alpine Linux

```bash
apk add \
  leptonica-dev \
  tesseract-ocr-dev \
  poppler-dev \
  pkgconfig
```

### Windows

On Windows, you'll need to:

1. Install [MSYS2](https://www.msys2.org/)
2. In MSYS2 terminal:
```bash
pacman -S mingw-w64-x86_64-leptonica
pacman -S mingw-w64-x86_64-tesseract-ocr
pacman -S mingw-w64-x86_64-poppler
```

## Troubleshooting

### pkg-config not found

If you get errors about pkg-config:

1. **macOS**: `brew install pkg-config`
2. **Linux**: Install pkg-config for your distribution
3. Set `PKG_CONFIG_PATH` to include the directory with `.pc` files

### Library not found

If libraries are installed but not found:

```bash
# Find where .pc files are located
find /usr -name "lept.pc" 2>/dev/null
find /opt -name "lept.pc" 2>/dev/null

# Add to PKG_CONFIG_PATH
export PKG_CONFIG_PATH="/path/to/pc/files:$PKG_CONFIG_PATH"
```

### Building without certain features

Currently, all dependencies are required. Future versions may make OCR optional.

## Docker

For containerized environments, here's a sample Dockerfile:

```dockerfile
FROM ruby:3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
  libleptonica-dev \
  libtesseract-dev \
  libpoppler-cpp-dev \
  tesseract-ocr \
  pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Your application setup
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
```

## CI/CD

For GitHub Actions, add this step before building:

```yaml
- name: Install system dependencies
  run: |
    if [ "$RUNNER_OS" == "Linux" ]; then
      sudo apt-get update
      sudo apt-get install -y libleptonica-dev libtesseract-dev libpoppler-cpp-dev
    elif [ "$RUNNER_OS" == "macOS" ]; then
      brew install leptonica tesseract poppler
    fi
```