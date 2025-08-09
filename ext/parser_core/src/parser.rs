use magnus::{
    class, function, method, prelude::*, scan_args, Error, RHash, RModule, Ruby, Value, Module,
};
use parser_core;

#[derive(Debug, Clone)]
#[magnus::wrap(class = "ParserCore::Parser", free_immediately, size)]
pub struct Parser {
    // Parser configuration - we keep this for Ruby API compatibility
    config: ParserConfig,
}

#[derive(Debug, Clone)]
struct ParserConfig {
    strict_mode: bool,
    max_depth: usize,
    encoding: String,
}

impl Default for ParserConfig {
    fn default() -> Self {
        Self {
            strict_mode: false,
            max_depth: 100,
            encoding: "UTF-8".to_string(),
        }
    }
}

impl Parser {
    /// Create a new Parser instance with optional configuration
    fn new(ruby: &Ruby, args: &[Value]) -> Result<Self, Error> {
        let args = scan_args::scan_args::<(), (Option<RHash>,), (), (), (), ()>(args)?;
        let options = args.optional.0;

        let mut config = ParserConfig::default();

        if let Some(opts) = options {
            if let Some(strict) = opts.get(ruby.to_symbol("strict_mode")) {
                config.strict_mode = bool::try_convert(strict)?;
            }
            if let Some(depth) = opts.get(ruby.to_symbol("max_depth")) {
                config.max_depth = usize::try_convert(depth)?;
            }
            if let Some(encoding) = opts.get(ruby.to_symbol("encoding")) {
                config.encoding = String::try_convert(encoding)?;
            }
        }

        Ok(Self { config })
    }

    /// Parse input string using parser-core
    fn parse(&self, input: String) -> Result<String, Error> {
        if input.is_empty() {
            return Err(Error::new(
                magnus::exception::arg_error(),
                "Input cannot be empty",
            ));
        }

        // Convert string to bytes and use parser-core
        let bytes = input.as_bytes();
        match parser_core::parse(bytes) {
            Ok(text) => Ok(text),
            Err(_e) => {
                // If parser-core can't parse it (not a document format), return the input
                // This maintains compatibility with the Ruby API
                Ok(input)
            }
        }
    }

    /// Parse a file using parser-core
    fn parse_file(&self, path: String) -> Result<String, Error> {
        use std::fs;

        // Read file as bytes for parser-core
        let data = fs::read(&path)
            .map_err(|e| Error::new(magnus::exception::io_error(), format!("Failed to read file: {}", e)))?;

        // Use parser-core to extract text
        match parser_core::parse(&data) {
            Ok(text) => Ok(text),
            Err(e) => Err(Error::new(
                magnus::exception::runtime_error(),
                format!("Failed to parse file: {:?}", e),
            ))
        }
    }

    /// Parse raw bytes using parser-core
    fn parse_bytes(&self, data: Vec<u8>) -> Result<String, Error> {
        if data.is_empty() {
            return Err(Error::new(
                magnus::exception::arg_error(),
                "Data cannot be empty",
            ));
        }

        match parser_core::parse(&data) {
            Ok(text) => Ok(text),
            Err(e) => Err(Error::new(
                magnus::exception::runtime_error(),
                format!("Failed to parse data: {:?}", e),
            ))
        }
    }

    /// Get parser configuration
    fn config(&self) -> Result<RHash, Error> {
        let ruby = Ruby::get().unwrap();
        let hash = ruby.hash_new();
        hash.aset(ruby.to_symbol("strict_mode"), self.config.strict_mode)?;
        hash.aset(ruby.to_symbol("max_depth"), self.config.max_depth)?;
        hash.aset(ruby.to_symbol("encoding"), self.config.encoding.as_str())?;
        Ok(hash)
    }

    /// Check if parser is in strict mode
    fn strict_mode(&self) -> bool {
        self.config.strict_mode
    }
}

/// Module-level function to parse a file directly
fn parse_file_direct(path: String) -> Result<String, Error> {
    use std::fs;

    let data = fs::read(&path)
        .map_err(|e| Error::new(magnus::exception::io_error(), format!("Failed to read file: {}", e)))?;

    match parser_core::parse(&data) {
        Ok(text) => Ok(text),
        Err(e) => Err(Error::new(
            magnus::exception::runtime_error(),
            format!("Failed to parse file: {:?}", e),
        ))
    }
}

/// Module-level function to parse bytes directly
fn parse_bytes_direct(data: Vec<u8>) -> Result<String, Error> {
    if data.is_empty() {
        return Err(Error::new(
            magnus::exception::arg_error(),
            "Data cannot be empty",
        ));
    }

    match parser_core::parse(&data) {
        Ok(text) => Ok(text),
        Err(e) => Err(Error::new(
            magnus::exception::runtime_error(),
            format!("Failed to parse data: {:?}", e),
        ))
    }
}

/// Initialize the Parser class
pub fn init(_ruby: &Ruby, module: RModule) -> Result<(), Error> {
    let class = module.define_class("Parser", class::object())?;

    // Instance methods
    class.define_singleton_method("new", function!(Parser::new, -1))?;
    class.define_method("parse", method!(Parser::parse, 1))?;
    class.define_method("parse_file", method!(Parser::parse_file, 1))?;
    class.define_method("parse_bytes", method!(Parser::parse_bytes, 1))?;
    class.define_method("config", method!(Parser::config, 0))?;
    class.define_method("strict_mode?", method!(Parser::strict_mode, 0))?;

    // Module-level convenience methods
    module.define_singleton_method("parse_file", function!(parse_file_direct, 1))?;
    module.define_singleton_method("parse_bytes", function!(parse_bytes_direct, 1))?;

    Ok(())
}