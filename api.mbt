///|
/// Default offline budgets: 8 MiB input, 100,000 segments, 64 KiB per segment,
/// 1,024 elements per segment, 128 components per element, 100 diagnostics.
pub fn default_limits() -> ParseLimits {
  {
    max_input_bytes: 8388608,
    max_segments: 100000,
    max_segment_bytes: 65536,
    max_elements: 1024,
    max_components: 128,
    max_diagnostics: 100,
  }
}

///|
/// Parse bytes under explicit limits. No I/O, time, network or implicit decoding.
pub fn parse(
  input : Bytes,
  limits? : ParseLimits = default_limits(),
) -> ParseResult {
  if limits.max_input_bytes <= 0 ||
    limits.max_segments <= 0 ||
    limits.max_segment_bytes <= 0 ||
    limits.max_elements <= 0 ||
    limits.max_components <= 0 ||
    limits.max_diagnostics <= 0 {
    return parse_failure(
      diagnostic(
        "R_LIMITS_INVALID",
        Resource,
        0,
        0,
        "All resource limits must be positive.",
      ),
    )
  }
  if input.length() > limits.max_input_bytes {
    return parse_failure(
      diagnostic(
        "R_INPUT_BYTES",
        Resource,
        0,
        input.length(),
        "Input exceeds the configured byte budget.",
      ),
    )
  }
  let profile = match detect_syntax(input) {
    Ok(profile) => profile
    Err(error) => return parse_failure(error)
  }
  let segments : Array[Segment] = []
  let mut pos = profile.body_start
  while pos < input.length() {
    if input[pos] == b'\r' || input[pos] == b'\n' {
      pos = pos + 1
      continue
    }
    if segments.length() >= limits.max_segments {
      return parse_failure(
        diagnostic(
          "R_SEGMENTS",
          Resource,
          pos,
          input.length().min(pos + 3),
          "Segment count exceeds the configured budget.",
          segment_index=segments.length() + 1,
        ),
      )
    }
    match scan_segment(input, pos, profile, limits, segments.length() + 1) {
      Err(error) => return parse_failure(error)
      Ok((segment, next)) => {
        segments.push(segment)
        pos = next
      }
    }
  }
  let end = if segments.is_empty() {
    profile.body_start
  } else {
    segments[segments.length() - 1].span.end
  }
  let document : Document = {
    profile,
    segments,
    span: { start: profile.body_start, end, },
  }
  let envelope = validate_envelope(
    document,
    max_diagnostics=limits.max_diagnostics,
  )
  {
    document: Some(document),
    interchange: envelope.interchange,
    diagnostics: envelope.diagnostics,
    syntax: Passed,
    envelope: envelope.status,
    rules: NotChecked,
  }
}

///|
fn parse_failure(error : Diagnostic) -> ParseResult {
  {
    document: None,
    interchange: None,
    diagnostics: [error],
    syntax: Failed,
    envelope: NotChecked,
    rules: NotChecked,
  }
}
