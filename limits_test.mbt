///|
fn resource_error(
  input : Bytes,
  limits : @MoonEdifact.ParseLimits,
  code : String,
) -> Unit raise {
  let r = @MoonEdifact.parse(input, limits~)
  assert_eq(r.syntax, @MoonEdifact.Failed)
  assert_true(r.document is None)
  assert_eq(r.diagnostics[0].code, code)
  assert_eq(r.diagnostics[0].layer, @MoonEdifact.Resource)
  assert_eq(r.diagnostics[0].severity, "error")
  assert_true(r.diagnostics[0].span.end <= input.length())
}

///|
test "edge/limits/input exactly at budget" {
  let input = b"UNB+UNOA:3+S'"
  let limits = {
    ..@MoonEdifact.default_limits(),
    max_input_bytes: input.length(),
  }
  assert_eq(@MoonEdifact.parse(input, limits~).syntax, @MoonEdifact.Passed)
}

///|
test "invalid/limits/input over budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_input_bytes: 12, }
  resource_error(b"UNB+UNOA:3+S'", limits, "R_INPUT_BYTES")
}

///|
test "edge/limits/segment count exactly at budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_segments: 1, }
  assert_eq(
    @MoonEdifact.parse(b"UNB+UNOA:3+S'", limits~).syntax,
    @MoonEdifact.Passed,
  )
}

///|
test "invalid/limits/segment count over budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_segments: 1, }
  resource_error(b"UNB+UNOA:3+S'XYZ+A'", limits, "R_SEGMENTS")
}

///|
test "edge/limits/raw segment exactly at budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_segment_bytes: 13, }
  assert_eq(
    @MoonEdifact.parse(b"UNB+UNOA:3+S'", limits~).syntax,
    @MoonEdifact.Passed,
  )
}

///|
test "invalid/limits/segment byte budget includes terminator" {
  let limits = { ..@MoonEdifact.default_limits(), max_segment_bytes: 12, }
  resource_error(b"UNB+UNOA:3+S'", limits, "R_SEGMENT_BYTES")
}

///|
test "invalid/limits/released bytes count toward raw budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_segment_bytes: 13, }
  resource_error(b"UNB+UNOA:3+S'XYZ+AAAAAAA?+'", limits, "R_SEGMENT_BYTES")
}

///|
test "edge/limits/elements exactly at budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_elements: 2, }
  assert_eq(
    @MoonEdifact.parse(b"UNB+UNOA:3+S'", limits~).syntax,
    @MoonEdifact.Passed,
  )
}

///|
test "invalid/limits/elements over budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_elements: 2, }
  resource_error(b"UNB+UNOA:3+S'XYZ+A+B+C'", limits, "R_ELEMENTS")
}

///|
test "edge/limits/components exactly at budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_components: 2, }
  assert_eq(
    @MoonEdifact.parse(b"UNB+UNOA:3+S'XYZ+A:B'", limits~).syntax,
    @MoonEdifact.Passed,
  )
}

///|
test "invalid/limits/components over budget" {
  let limits = { ..@MoonEdifact.default_limits(), max_components: 2, }
  resource_error(b"UNB+UNOA:3+S'XYZ+A:B:C'", limits, "R_COMPONENTS")
}

///|
test "invalid/limits/nonpositive budgets rejected before input" {
  for
    limits in [
      { ..@MoonEdifact.default_limits(), max_input_bytes: 0, },
      { ..@MoonEdifact.default_limits(), max_segments: -1, },
      { ..@MoonEdifact.default_limits(), max_segment_bytes: 0, },
      { ..@MoonEdifact.default_limits(), max_elements: 0, },
      { ..@MoonEdifact.default_limits(), max_components: 0, },
      { ..@MoonEdifact.default_limits(), max_diagnostics: 0, },
    ] {
    resource_error(b"", limits, "R_LIMITS_INVALID")
  }
}

///|
test "invalid/limits/diagnostic exhaustion stops safely" {
  let limits = { ..@MoonEdifact.default_limits(), max_diagnostics: 1, }
  let r = @MoonEdifact.parse(b"UNB+UNOA:3+S'XYZ+A'XYZ+B'UNZ+0+I'", limits~)
  assert_eq(r.syntax, @MoonEdifact.Passed)
  assert_eq(r.envelope, @MoonEdifact.Failed)
  assert_eq(r.diagnostics.length(), 1)
  assert_eq(r.diagnostics[0].code, "R_DIAGNOSTICS")
}

///|
test "edge/limits/exact diagnostic budget keeps original code" {
  let limits = { ..@MoonEdifact.default_limits(), max_diagnostics: 1, }
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'UNT+9+1'UNZ+1+I'",
    limits~,
  )
  assert_eq(r.diagnostics.length(), 1)
  assert_eq(r.diagnostics[0].code, "E_MESSAGE_COUNT")
}

///|
test "invalid/limits/standalone validator invalid budget" {
  let doc = @MoonEdifact.parse(b"UNB+UNOA:3+S'").document.unwrap()
  let result = @MoonEdifact.validate_envelope(doc, max_diagnostics=0)
  assert_eq(result.diagnostics[0].code, "R_LIMITS_INVALID")
  assert_eq(result.status, @MoonEdifact.Failed)
}
