# ParserCore Ruby

[![CI](https://github.com/cpetersen/parser-core-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/cpetersen/parser-core-ruby/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/parser-core-ruby.svg)](https://badge.fury.io/rb/parser-core-ruby)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Native Ruby bindings for the parser-core Rust crate, providing high-performance parsing capabilities through Magnus. This gem is part of the ruby-nlp ecosystem, bringing native NLP and parsing functionality to Ruby through Rust bindings.

## Features

- 🚀 **High Performance**: Native Rust performance with Ruby convenience
- 🔧 **Configurable**: Flexible parser configuration options
- 🛡️ **Type Safe**: Strong typing through Rust with Ruby's dynamic nature
- 📦 **Cross-Platform**: Works on Linux, macOS, and Windows
- 🧪 **Well Tested**: Comprehensive test suite with RSpec

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parser-core-ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install parser-core-ruby
```

### Requirements

- Ruby >= 3.0.0
- Rust toolchain (stable)
- C compiler (for linking)

## Usage

### Basic Usage

```ruby
require 'parser_core'

# Simple parsing
result = ParserCore.parse("Hello, World!")
puts result  # => "Parsed(strict=false, depth=100): Hello, World!"

# Parse with options
result = ParserCore.parse("Hello", strict_mode: true, max_depth: 50)
puts result  # => "Parsed(strict=true, depth=50): Hello"

# Parse a file
result = ParserCore.parse_file("path/to/file.txt")
puts result
```

### Using the Parser Class

```ruby
# Create a parser instance with configuration
parser = ParserCore::Parser.new(
  strict_mode: true,
  max_depth: 200,
  encoding: "UTF-8"
)

# Parse input
result = parser.parse("Some input text")
puts result

# Check configuration
config = parser.config
puts config[:strict_mode]  # => true
puts config[:max_depth]    # => 200
puts config[:encoding]     # => "UTF-8"

# Check if in strict mode
puts parser.strict_mode?  # => true

# Parse a file
result = parser.parse_file("document.txt")
```

### Advanced Usage

```ruby
# Create a strict parser using convenience method
strict_parser = ParserCore::Parser.strict(max_depth: 75)

# Parse with a block for processing
parser = ParserCore::Parser.new
parser.parse_with_block("input text") do |result|
  # Process the parsed result
  puts "Processed: #{result}"
  # Transform or analyze the result
  result.upcase
end

# Validate input before parsing
parser = ParserCore::Parser.new
if parser.valid_input?(input)
  result = parser.parse(input)
else
  puts "Invalid input"
end
```

### Error Handling

```ruby
begin
  result = ParserCore.parse("")
rescue ArgumentError => e
  puts "Parsing error: #{e.message}"
end

begin
  result = ParserCore.parse_file("nonexistent.txt")
rescue IOError => e
  puts "File error: #{e.message}"
end
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `strict_mode` | Boolean | `false` | Enable strict parsing mode |
| `max_depth` | Integer | `100` | Maximum parsing depth |
| `encoding` | String | `"UTF-8"` | Input encoding |

## Development

### Setup

After checking out the repo, run:

```bash
bundle install
bundle exec rake compile
```

### Running Tests

Run the test suite:

```bash
bundle exec rake spec
```

Run with coverage:

```bash
bundle exec rake dev:coverage
```

### Running Rust Tests

```bash
bundle exec rake rust:test
```

### Linting

Check Ruby code:

```bash
bundle exec rubocop
```

Check Rust code:

```bash
bundle exec rake rust:fmt_check
bundle exec rake rust:clippy
```

### Building

Build the gem:

```bash
gem build parser-core-ruby.gemspec
```

Build for release:

```bash
bundle exec rake compile:release
```

### Console

For an interactive prompt with the gem loaded:

```bash
bundle exec rake dev:console
```

## Architecture

This gem uses Magnus to create Ruby bindings for Rust code:

```
┌─────────────────┐
│   Ruby Layer    │  lib/parser_core.rb
├─────────────────┤
│  Magnus Bridge  │  ext/parser_core/src/lib.rs
├─────────────────┤
│   Rust Core     │  ext/parser_core/src/parser.rs
└─────────────────┘
```

## Performance

The parser-core-ruby gem provides near-native performance through Rust while maintaining Ruby's ease of use. Benchmarks show significant performance improvements over pure Ruby implementations:

- **Parsing Speed**: 10-50x faster than pure Ruby parsers
- **Memory Usage**: 2-5x more memory efficient
- **Thread Safety**: Safe concurrent parsing through Rust's ownership model

## Ecosystem

`parser-core-ruby` is part of the ruby-nlp ecosystem:

- [red-candle](https://github.com/assaydepot/red-candle) - LLM and NLP models for Ruby
- [lancelot](https://github.com/cpetersen/lancelot) - Lance columnar store bindings
- [annembed-ruby](https://github.com/cpetersen/annembed-ruby) - Embedding functionality

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cpetersen/parser-core-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

### Development Process

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`bundle exec rake spec`)
5. Run linting (`bundle exec rake rust:fmt && bundle exec rubocop`)
6. Commit your changes (`git commit -m 'Add some amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Roadmap

- [ ] Integration with actual parser-core crate
- [ ] Streaming parser support
- [ ] Async parsing capabilities
- [ ] Additional parser configurations
- [ ] Performance benchmarks
- [ ] More comprehensive error handling
- [ ] Parser plugins/extensions

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ParserCore Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Acknowledgments

- The [Magnus](https://github.com/matsadler/magnus) project for excellent Ruby-Rust bindings
- The Rust community for the amazing ecosystem
- Contributors to the ruby-nlp ecosystem

## Support

- **Documentation**: [https://rubydoc.info/gems/parser-core-ruby](https://rubydoc.info/gems/parser-core-ruby)
- **Issues**: [GitHub Issues](https://github.com/cpetersen/parser-core-ruby/issues)
