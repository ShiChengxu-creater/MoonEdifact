///|
/// Half-open offsets into the caller's original Bytes. End excludes the last byte.
pub(all) struct SourceSpan {
  start : Int
  end : Int
} derive(Debug, Eq)

///|
/// The layer that produced a diagnostic.
pub(all) enum Layer {
  Syntax
  Envelope
  Resource
} derive(Debug, Eq)

///|
/// All diagnostics are errors in 0.1.0. Messages never include input field values.
pub(all) struct Diagnostic {
  code : String
  layer : Layer
  span : SourceSpan
  segment_index : Int?
  hint : String
} derive(Debug, Eq)

///|
/// Syntax 3 service characters and the first byte after an optional UNA.
pub(all) struct SyntaxProfile {
  component : Byte
  element : Byte
  decimal : Byte
  release : Byte
  reserved : Byte
  terminator : Byte
  charset : String
  version : Int
  explicit_una : Bool
  body_start : Int
} derive(Debug, Eq)

///|
fn diagnostic(
  code : String,
  layer : Layer,
  start : Int,
  end : Int,
  hint : String,
  segment_index? : Int,
) -> Diagnostic {
  { code, layer, span: { start, end, }, segment_index, hint, }
}

///|
pub extend SourceSpan with @debug.Debug::{to_repr}

///|
pub extend SourceSpan with Eq::{equal, not_equal}

///|
pub extend Layer with @debug.Debug::{to_repr}

///|
pub extend Layer with Eq::{equal, not_equal}

///|
pub extend Diagnostic with @debug.Debug::{to_repr}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend SyntaxProfile with @debug.Debug::{to_repr}

///|
pub extend SyntaxProfile with Eq::{equal, not_equal}
