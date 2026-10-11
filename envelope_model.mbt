///|
/// A closed direct message with inclusive one-based indexes into Document.segments.
pub(all) struct Message {
  reference : Bytes
  first_segment : Int
  last_segment : Int
  span : SourceSpan
} derive(Debug, Eq)

///|
/// Direct messages in a single interchange. Invalid envelopes remain inspectable.
pub(all) struct Interchange {
  messages : Array[Message]
  span : SourceSpan
} derive(Debug, Eq)

///|
/// Envelope validation independently reports its status and diagnostics.
pub(all) struct EnvelopeResult {
  interchange : Interchange?
  diagnostics : Array[Diagnostic]
  status : CheckStatus
} derive(Debug, Eq)

///|
pub extend Message with @debug.Debug::{to_repr}

///|
pub extend Message with Eq::{equal, not_equal}

///|
pub extend Interchange with @debug.Debug::{to_repr}

///|
pub extend Interchange with Eq::{equal, not_equal}

///|
pub extend EnvelopeResult with @debug.Debug::{to_repr}

///|
pub extend EnvelopeResult with Eq::{equal, not_equal}
