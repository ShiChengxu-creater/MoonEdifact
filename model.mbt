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

///|
/// Resource budgets. All values must be positive; raw segment lengths include terminators.
pub(all) struct ParseLimits {
  max_input_bytes : Int
  max_segments : Int
  max_segment_bytes : Int
  max_elements : Int
  max_components : Int
  max_diagnostics : Int
} derive(Debug, Eq)

///|
/// A logical byte value and its raw span, including release markers.
pub(all) struct Component {
  value : Bytes
  span : SourceSpan
} derive(Debug, Eq)

///|
/// Components are never dropped, including empty leading, middle and trailing values.
pub(all) struct Element {
  components : Array[Component]
  span : SourceSpan
} derive(Debug, Eq)

///|
/// The span includes the segment terminator; index is one-based and excludes UNA.
pub(all) struct Segment {
  tag : String
  index : Int
  elements : Array[Element]
  span : SourceSpan
} derive(Debug, Eq)

///|
/// Generic syntax model. Business segment semantics are not checked.
pub(all) struct Document {
  profile : SyntaxProfile
  segments : Array[Segment]
  span : SourceSpan
} derive(Debug, Eq)

///|
/// A separate state for each validation layer.
pub(all) enum CheckStatus {
  Passed
  Failed
  NotChecked
} derive(Debug, Eq)

///|
/// Syntax failures return no partial document. Business rules are always NotChecked.
pub(all) struct ParseResult {
  document : Document?
  interchange : Interchange?
  diagnostics : Array[Diagnostic]
  syntax : CheckStatus
  envelope : CheckStatus
  rules : CheckStatus
} derive(Debug, Eq)

///|
pub extend ParseLimits with @debug.Debug::{to_repr}

///|
pub extend ParseLimits with Eq::{equal, not_equal}

///|
pub extend Component with @debug.Debug::{to_repr}

///|
pub extend Component with Eq::{equal, not_equal}

///|
pub extend Element with @debug.Debug::{to_repr}

///|
pub extend Element with Eq::{equal, not_equal}

///|
pub extend Segment with @debug.Debug::{to_repr}

///|
pub extend Segment with Eq::{equal, not_equal}

///|
pub extend Document with @debug.Debug::{to_repr}

///|
pub extend Document with Eq::{equal, not_equal}

///|
pub extend CheckStatus with @debug.Debug::{to_repr}

///|
pub extend CheckStatus with Eq::{equal, not_equal}

///|
pub extend ParseResult with @debug.Debug::{to_repr}

///|
pub extend ParseResult with Eq::{equal, not_equal}
