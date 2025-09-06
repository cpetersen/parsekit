# Contributing to ParseKit Ruby

First off, thank you for considering contributing to ParseKit Ruby! It's people like you that make ParseKit Ruby such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [your.email@example.com].

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem
* **Describe the exact steps which reproduce the problem** in as many details as possible
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior
* **Explain which behavior you expected to see instead and why**
* **Include details about your configuration and environment**:
  * Ruby version (run `ruby -v`)
  * Rust version (run `rustc --version`)
  * Operating system and version
  * ParseKit Ruby version

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible
* **Provide specific examples to demonstrate the steps** or provide code snippets
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why
* **Explain why this enhancement would be useful** to most ParseKit Ruby users

### Pull Requests

Please follow these steps to have your contribution considered by the maintainers:

1. Follow all instructions in [the template](.github/pull_request_template.md)
2. Follow the [styleguides](#styleguides)
3. After you submit your pull request, verify that all [status checks](https://help.github.com/articles/about-status-checks/) are passing

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/parsekit.git
   cd parsekit
   ```

2. **Install Ruby dependencies**
   ```bash
   bundle install
   ```

3. **Install Rust toolchain**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup component add rustfmt clippy
   ```

4. **Compile the extension**
   ```bash
   bundle exec rake compile
   ```

5. **Run tests**
   ```bash
   bundle exec rake spec
   ```

## Styleguides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* Consider starting the commit message with an applicable emoji:
  * 🎨 `:art:` when improving the format/structure of the code
  * 🐎 `:racehorse:` when improving performance
  * 📝 `:memo:` when writing docs
  * 🐛 `:bug:` when fixing a bug
  * 🔥 `:fire:` when removing code or files
  * 💚 `:green_heart:` when fixing the CI build
  * ✅ `:white_check_mark:` when adding tests
  * 🔒 `:lock:` when dealing with security
  * ⬆️ `:arrow_up:` when upgrading dependencies
  * ⬇️ `:arrow_down:` when downgrading dependencies

### Ruby Styleguide

* Follow the [Ruby Style Guide](https://rubystyle.guide/)
* Use RuboCop to check your code:
  ```bash
  bundle exec rubocop
  ```
* Write RSpec tests for new functionality
* Maintain test coverage above 90%

### Rust Styleguide

* Follow the [Rust Style Guide](https://doc.rust-lang.org/1.0.0/style/)
* Use rustfmt to format your code:
  ```bash
  cd ext/parsekit
  cargo fmt
  ```
* Use clippy to lint your code:
  ```bash
  cd ext/parsekit
  cargo clippy
  ```
* Write tests for new Rust functionality
* Document public APIs with rustdoc comments

### Documentation Styleguide

* Use [YARD](https://yardoc.org/) for Ruby documentation
* Use rustdoc for Rust documentation
* Include examples in documentation
* Keep README.md up to date with new features

## Testing

### Ruby Tests

Run all tests:
```bash
bundle exec rake spec
```

Run specific test file:
```bash
bundle exec rspec spec/parsekit_spec.rb
```

Run with coverage:
```bash
COVERAGE=true bundle exec rake spec
```

### Rust Tests

Run Rust tests:
```bash
bundle exec rake rust:test
```

Or directly:
```bash
cd ext/parsekit
cargo test
```

### Integration Tests

The gem includes integration tests that verify Ruby-Rust interaction:
```bash
bundle exec rspec spec/integration/
```

## Benchmarking

Run benchmarks:
```bash
bundle exec rake benchmark
```

Compare with pure Ruby implementation:
```bash
bundle exec ruby benchmark/comparison.rb
```

## Releasing

Releases are managed by maintainers. The process is:

1. Update version in `lib/parsekit/version.rb`
2. Update CHANGELOG.md
3. Commit changes: `git commit -am "Release version X.Y.Z"`
4. Create tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
5. Push changes: `git push origin main --tags`
6. GitHub Actions will automatically build and publish to RubyGems

## Additional Resources

* [Magnus Documentation](https://docs.rs/magnus/latest/magnus/)
* [Ruby C API Documentation](https://docs.ruby-lang.org/en/master/extension_rdoc.html)
* [Rust Book](https://doc.rust-lang.org/book/)
* [RSpec Documentation](https://rspec.info/)

## Questions?

Feel free to open an issue with the `question` label or start a discussion in the [GitHub Discussions](https://github.com/scientist-labs/parsekit/discussions) area.
