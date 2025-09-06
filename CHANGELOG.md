# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- Nothing yet

## [0.1.0] - 2024-08-09

### Added
- Initial release of parsekit
- Basic parser functionality with Ruby bindings via Magnus
- Support for parsing strings and files
- Configurable parser with options (strict_mode, max_depth, encoding)
- Parser class with instance methods
- Module-level convenience methods
- Error handling with custom error classes
- Thread-safe parsing operations
- Cross-platform support (Linux, macOS, Windows)
- Ruby 3.0+ support
- Comprehensive test suite with RSpec
- CI/CD with GitHub Actions
- Documentation and examples
- Integration with ruby-nlp ecosystem

### Technical Details
- Built with Magnus 0.7 for Ruby-Rust bindings
- Uses rb_sys 0.9 for build system integration
- Rust edition 2021
- Cross-compilation support for multiple platforms

[Unreleased]: https://github.com/scientist-labs/parsekit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/scientist-labs/parsekit/releases/tag/v0.1.0
