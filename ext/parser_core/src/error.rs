use magnus::{define_class, exception, Error, Module, Ruby};

/// Custom error types for ParserCore
#[derive(Debug)]
pub enum ParserError {
    ParseError(String),
    ConfigError(String),
    IoError(String),
}

impl ParserError {
    /// Convert to Magnus Error
    pub fn to_error(&self, ruby: &Ruby) -> Error {
        match self {
            ParserError::ParseError(msg) => {
                Error::new(ruby.get_inner(&PARSE_ERROR_CLASS), msg.clone())
            }
            ParserError::ConfigError(msg) => {
                Error::new(ruby.get_inner(&CONFIG_ERROR_CLASS), msg.clone())
            }
            ParserError::IoError(msg) => {
                Error::new(exception::io_error(), msg.clone())
            }
        }
    }
}

// Global references to error classes
static mut PARSE_ERROR_CLASS: Option<magnus::value::Opaque<magnus::Ruby>> = None;
static mut CONFIG_ERROR_CLASS: Option<magnus::value::Opaque<magnus::Ruby>> = None;

/// Initialize error classes
pub fn init(ruby: &Ruby, module: &Module) -> Result<(), Error> {
    // Define base error class
    let base_error = module.define_class("Error", ruby.exception_standard_error())?;
    
    // Define specific error classes
    let parse_error = module.define_class("ParseError", base_error)?;
    let config_error = module.define_class("ConfigError", base_error)?;
    
    // Store references for later use (this is safe because we're in init)
    unsafe {
        PARSE_ERROR_CLASS = Some(ruby.get_inner(&parse_error));
        CONFIG_ERROR_CLASS = Some(ruby.get_inner(&config_error));
    }
    
    Ok(())
}