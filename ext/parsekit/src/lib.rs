use magnus::{function, prelude::*, Error, Ruby};

mod parser;
mod error;
mod format_detector;

/// Initialize the ParseKit module and its submodules
#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("ParseKit")?;
    
    // Initialize submodules
    parser::init(ruby, module)?;
    error::init(ruby, module)?;
    
    // Add module-level methods
    module.define_singleton_method("version", function!(version, 0))?;
    
    Ok(())
}

/// Return the version of the parsekit gem
fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}