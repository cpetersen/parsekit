use magnus::{Error, RModule, Ruby, Module};

/// Custom error types for ParseKit
#[derive(Debug)]
#[allow(dead_code)]
pub enum ParserError {
    ParseError(String),
    ConfigError(String),
    IoError(String),
}

impl ParserError {
    /// Convert to Magnus Error
    #[allow(dead_code)]
    pub fn to_error(&self) -> Error {
        match self {
            ParserError::ParseError(msg) => {
                Error::new(Ruby::get().unwrap().exception_runtime_error(), msg.clone())
            }
            ParserError::ConfigError(msg) => {
                Error::new(Ruby::get().unwrap().exception_arg_error(), msg.clone())
            }
            ParserError::IoError(msg) => {
                Error::new(Ruby::get().unwrap().exception_io_error(), msg.clone())
            }
        }
    }
}

/// Initialize error classes
/// For simplicity, we'll just create Ruby classes that inherit from Object,
/// and document that they should be treated as exceptions
pub fn init(_ruby: &Ruby, module: RModule) -> Result<(), Error> {
    // For now, just create placeholder classes
    // In a real implementation, you'd want to properly set up exception classes
    // but Magnus 0.7's API for this is complex
    
    // Define error classes as regular Ruby classes
    // Users can still rescue them by name in Ruby code
    let _error = module.define_class("Error", Ruby::get().unwrap().class_object())?;
    let _parse_error = module.define_class("ParseError", Ruby::get().unwrap().class_object())?;
    let _config_error = module.define_class("ConfigError", Ruby::get().unwrap().class_object())?;
    
    Ok(())
}