///|
test "valid/cli/inspect arguments" {
  let options = @options.parse_args(["inspect", "input.edi", "--json"]).unwrap()
  assert_eq(options.action, @options.Inspect)
  assert_eq(options.file, "input.edi")
  assert_true(options.json)
}

///|
test "valid/cli/validate defaults" {
  let o = @options.parse_args(["validate", "input.edi"]).unwrap()
  assert_eq(o.action, @options.Validate)
  assert_false(o.json)
  assert_false(o.show_values)
}

///|
test "valid/cli/custom limits" {
  let o = @options.parse_args([
    "inspect", "--max-bytes", "1000", "--max-segments", "9", "--max-segment-bytes",
    "500", "--max-elements", "20", "--max-components", "10", "--max-diagnostics",
    "4", "input.edi",
  ]).unwrap()
  assert_eq(o.limits.max_input_bytes, 1000)
  assert_eq(o.limits.max_segments, 9)
  assert_eq(o.limits.max_segment_bytes, 500)
  assert_eq(o.limits.max_elements, 20)
  assert_eq(o.limits.max_components, 10)
  assert_eq(o.limits.max_diagnostics, 4)
}

///|
test "valid/cli/show values opt in" {
  assert_true(
    @options.parse_args(["inspect", "input.edi", "--show-values", "--json"]).unwrap().show_values,
  )
}

///|
test "valid/cli/dash filename after terminator" {
  assert_eq(
    @options.parse_args(["inspect", "--", "-input.edi"]).unwrap().file,
    "-input.edi",
  )
}

///|
test "valid/cli/help and version" {
  assert_eq(@options.parse_args(["--help"]).unwrap().action, @options.Help)
  assert_eq(
    @options.parse_args(["--version"]).unwrap().action,
    @options.Version,
  )
  assert_true(@options.help_text().contains("Exit codes"))
}

///|
test "invalid/cli/missing command and filename" {
  assert_true(@options.parse_args([]) is Err(_))
  assert_true(@options.parse_args(["inspect"]) is Err(_))
}

///|
test "invalid/cli/extra file" {
  assert_true(@options.parse_args(["inspect", "one.edi", "two.edi"]) is Err(_))
}

///|
test "invalid/cli/unknown flag" {
  assert_true(
    @options.parse_args(["inspect", "input.edi", "--unknown"]) is Err(_),
  )
}

///|
test "invalid/cli/invalid numeric budgets" {
  for
    number in [
      "0", "-1", "", "1.5", "1x", "2147483648", "999999999999999999999999",
    ] {
    assert_true(
      @options.parse_args(["inspect", "input.edi", "--max-bytes", number])
      is Err(_),
    )
  }
}

///|
test "invalid/cli/missing budget argument" {
  assert_true(
    @options.parse_args(["inspect", "input.edi", "--max-bytes"]) is Err(_),
  )
}

///|
test "invalid/cli/values without JSON" {
  assert_true(
    @options.parse_args(["inspect", "input.edi", "--show-values"]) is Err(_),
  )
}

///|
test "edge/cli/largest positive integer" {
  assert_eq(
    @options.parse_args(["inspect", "input.edi", "--max-bytes", "2147483647"]).unwrap().limits.max_input_bytes,
    2147483647,
  )
}
