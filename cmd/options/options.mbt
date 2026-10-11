///|
pub(all) enum Action {
  Help
  Version
  Inspect
  Validate
} derive(Debug, Eq)

///|
pub(all) struct Options {
  action : Action
  file : String
  json : Bool
  show_values : Bool
  limits : @lib.ParseLimits
} derive(Debug, Eq)

///|
pub extend Action with @debug.Debug::{to_repr}

///|
pub extend Action with Eq::{equal, not_equal}

///|
pub extend Options with @debug.Debug::{to_repr}

///|
pub extend Options with Eq::{equal, not_equal}

///|
/// Parse arguments after argv[0], without filesystem access.
pub fn parse_args(args : Array[String]) -> Result[Options, String] {
  if args.is_empty() {
    return Err("Expected inspect or validate and a file path.")
  }
  let action = match args[0] {
    "--help" | "-h" => Help
    "--version" => Version
    "inspect" => Inspect
    "validate" => Validate
    _ => return Err("Expected inspect or validate.")
  }
  if action == Help || action == Version {
    if args.length() != 1 {
      return Err("Help and version accept no additional arguments.")
    }
    return Ok({
      action,
      file: "",
      json: false,
      show_values: false,
      limits: @lib.default_limits(),
    })
  }
  let mut file : String? = None
  let mut json = false
  let mut show_values = false
  let mut limits = @lib.default_limits()
  let mut positional_only = false
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if positional_only {
      if file is Some(_) {
        return Err("Only one input file is accepted.")
      }
      file = Some(arg)
    } else {
      match arg {
        "--" => positional_only = true
        "--help" | "-h" =>
          return Ok({
            action: Help,
            file: "",
            json: false,
            show_values: false,
            limits,
          })
        "--json" => json = true
        "--show-values" => show_values = true
        "--max-bytes"
        | "--max-segments"
        | "--max-segment-bytes"
        | "--max-elements"
        | "--max-components"
        | "--max-diagnostics" => {
          if args.length() - i < 2 {
            return Err("A resource option requires a positive integer.")
          }
          let value = match positive_integer(args[i + 1]) {
            Some(n) => n
            None =>
              return Err(
                "Resource limits require positive 32-bit decimal integers.",
              )
          }
          limits = match arg {
            "--max-bytes" => { ..limits, max_input_bytes: value, }
            "--max-segments" => { ..limits, max_segments: value, }
            "--max-segment-bytes" => { ..limits, max_segment_bytes: value, }
            "--max-elements" => { ..limits, max_elements: value, }
            "--max-components" => { ..limits, max_components: value, }
            _ => { ..limits, max_diagnostics: value, }
          }
          i = i + 1
        }
        _ => {
          if arg.has_prefix("-") {
            return Err("Unknown option. Use --help for supported options.")
          }
          if file is Some(_) {
            return Err("Only one input file is accepted.")
          }
          file = Some(arg)
        }
      }
    }
    i = i + 1
  }
  if show_values && !json {
    return Err("--show-values requires --json.")
  }
  match file {
    Some(file) =>
      if file.is_empty() {
        Err("An input file path is required.")
      } else {
        Ok({ action, file, json, show_values, limits, })
      }
    None => Err("An input file path is required.")
  }
}

///|
fn positive_integer(text : String) -> Int? {
  if text.is_empty() {
    return None
  }
  let mut value = 0
  for c in text.iter() {
    if c < '0' || c > '9' {
      return None
    }
    let digit = c.to_int() - 48
    if value > (2147483647 - digit) / 10 {
      return None
    }
    value = value * 10 + digit
  }
  if value > 0 {
    Some(value)
  } else {
    None
  }
}

///|
/// CLI help with exit-code and privacy contracts.
pub fn help_text() -> String {
  "MoonEDIFACT 0.1.0\nUsage: moonedifact inspect FILE [--json] [--show-values]\n       moonedifact validate FILE [--json]\n       moonedifact --help | --version\n\nSyntax 3, UNOA / printable ASCII UNOB, direct messages only.\nBusiness rules are not checked. Reports hide values by default.\n--show-values with --json exposes logical business values.\nLimits: --max-bytes --max-segments --max-segment-bytes\n        --max-elements --max-components --max-diagnostics N\nEach limit accepts a positive 32-bit decimal integer.\nUse -- before a file name starting with a dash.\nExit codes: 0 syntax/envelopes passed; 1 report errors/limits; 2 usage/I/O."
}
