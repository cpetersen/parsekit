use magnus::{function, prelude::*, Error, Ruby};

mod parser;
mod error;

/// Initialize the ParserCore module and its submodules
#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("ParserCore")?;
    
    // Initialize submodules
    parser::init(ruby, module)?;
    error::init(ruby, module)?;
    
    // Add module-level methods
    module.define_singleton_method("version", function!(version, 0))?;
    
    Ok(())
}

/// Return the version of the parser-core-ruby gem
fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}