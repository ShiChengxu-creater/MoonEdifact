///|
test "valid/envelope/single message" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'BGM+220+X'UNT+3+1'UNZ+1+I'",
  )
  assert_eq(r.syntax, @MoonEdifact.Passed)
  assert_eq(r.envelope, @MoonEdifact.Passed)
  assert_eq(r.rules, @MoonEdifact.NotChecked)
  assert_eq(r.interchange.unwrap().messages.length(), 1)
  assert_eq(r.interchange.unwrap().messages[0].first_segment, 2)
  assert_eq(r.interchange.unwrap().messages[0].last_segment, 4)
}

///|
fn envelope_case(tail : Bytes) -> Bytes {
  b"UNB+UNOA:3+S+R+261011:1200+I'" + tail
}

///|
fn envelope_problem(
  input : Bytes,
  code : String,
) -> @MoonEdifact.Diagnostic raise {
  let r = @MoonEdifact.parse(input)
  assert_eq(r.syntax, @MoonEdifact.Passed)
  assert_eq(r.envelope, @MoonEdifact.Failed)
  for d in r.diagnostics {
    if d.code == code {
      assert_true(
        d.span.start >= 0 &&
        d.span.end >= d.span.start &&
        d.span.end <= input.length(),
      )
      return d
    }
  }
  fail("expected envelope diagnostic " + code)
}

///|
test "valid/envelope/two messages with custom UNA" {
  let r = @MoonEdifact.parse(
    b"UNA;*,! ~UNB*UNOA;3*S*R*261011;1200*I~UNH*1*ORDERS;D;96A;UN~XYZ*A!*B~UNT*3*1~UNH*2*INVOIC;D;96A;UN~FTX*X~UNT*3*2~UNZ*2*I~",
  )
  assert_eq(r.envelope, @MoonEdifact.Passed)
  assert_eq(r.diagnostics.length(), 0)
  let exchange = r.interchange.unwrap()
  assert_eq(exchange.messages.length(), 2)
  assert_eq(exchange.messages[0].first_segment, 2)
  assert_eq(exchange.messages[1].first_segment, 5)
  assert_eq(exchange.messages[1].last_segment, 7)
  assert_eq(exchange.messages[1].reference, b"2")
}

///|
test "valid/envelope/unknown business tag is preserved" {
  let r = @MoonEdifact.parse(
    envelope_case(b"UNH+1+UNKNOWN:D:96A:UN'XYZ+A'UNT+3+1'UNZ+1+I'"),
  )
  assert_eq(r.envelope, @MoonEdifact.Passed)
  assert_eq(r.rules, @MoonEdifact.NotChecked)
  assert_eq(r.document.unwrap().segments[2].tag, "XYZ")
}

///|
test "invalid/envelope/UNT count short by one" {
  let input = envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+2+1'UNZ+1+I'")
  let d = envelope_problem(input, "E_MESSAGE_COUNT")
  assert_eq(d.segment_index, Some(4))
  assert_eq(d.span.start, input.find(b"UNT+2").unwrap() + 4)
  assert_eq(d.span.end, d.span.start + 1)
}

///|
test "invalid/envelope/UNT count high by one" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+4+1'UNZ+1+I'"),
      "E_MESSAGE_COUNT",
    ),
  )
}

///|
test "invalid/envelope/UNT reference mismatch" {
  let input = envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+3+2'UNZ+1+I'")
  let d = envelope_problem(input, "E_MESSAGE_REFERENCE")
  assert_eq(d.span.start, input.find(b"UNT+3+2").unwrap() + 6)
  assert_eq(d.span.end, d.span.start + 1)
}

///|
test "invalid/envelope/UNZ count short by one" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+3+1'UNZ+0+I'"),
      "E_INTERCHANGE_COUNT",
    ),
  )
}

///|
test "invalid/envelope/UNZ count high by one" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+3+1'UNZ+2+I'"),
      "E_INTERCHANGE_COUNT",
    ),
  )
}

///|
test "invalid/envelope/UNZ reference mismatch" {
  let input = envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+3+1'UNZ+1+OTHER'")
  let d = envelope_problem(input, "E_INTERCHANGE_REFERENCE")
  assert_eq(d.span.start, input.find(b"UNZ+1+OTHER").unwrap() + 6)
  assert_eq(d.span.end, d.span.start + 5)
}

///|
test "invalid/envelope/missing UNZ" {
  let input = envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNT+3+1'")
  let d = envelope_problem(input, "E_UNZ_MISSING")
  assert_eq(d.span.start, input.length())
  assert_eq(d.span.end, input.length())
}

///|
test "invalid/envelope/UNZ before UNT" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'XYZ+A'UNZ+1+I'"),
      "E_UNT_MISSING",
    ),
  )
}

///|
test "invalid/envelope/orphan UNT" {
  ignore(envelope_problem(envelope_case(b"UNT+2+1'UNZ+0+I'"), "E_UNH_MISSING"))
}

///|
test "invalid/envelope/nested message header" {
  ignore(
    envelope_problem(
      envelope_case(
        b"UNH+1+ORDERS:D:96A:UN'UNH+2+ORDERS:D:96A:UN'UNT+2+2'UNZ+2+I'",
      ),
      "E_UNT_MISSING",
    ),
  )
}

///|
test "invalid/envelope/business segment outside message" {
  ignore(
    envelope_problem(
      envelope_case(b"XYZ+A'UNH+1+ORDERS:D:96A:UN'UNT+2+1'UNZ+1+I'"),
      "E_SEGMENT_OUTSIDE_MESSAGE",
    ),
  )
}

///|
test "invalid/envelope/duplicate message references" {
  ignore(
    envelope_problem(
      envelope_case(
        b"UNH+1+ORDERS:D:96A:UN'UNT+2+1'UNH+1+ORDERS:D:96A:UN'UNT+2+1'UNZ+2+I'",
      ),
      "E_MESSAGE_REFERENCE_DUPLICATE",
    ),
  )
}

///|
test "invalid/envelope/nonnumeric count" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'UNT+X+1'UNZ+1+I'"),
      "E_COUNT_INVALID",
    ),
  )
}

///|
test "invalid/envelope/oversized count cannot overflow" {
  ignore(
    envelope_problem(
      envelope_case(
        b"UNH+1+ORDERS:D:96A:UN'UNT+9999999999999999999999+1'UNZ+1+I'",
      ),
      "E_COUNT_INVALID",
    ),
  )
}

///|
test "invalid/envelope/composite count rejected" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'UNT+2:2+1'UNZ+1+I'"),
      "E_SERVICE_STRUCTURE",
    ),
  )
}

///|
test "invalid/envelope/trailer extra field" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'UNT+2+1+EXTRA'UNZ+1+I'"),
      "E_SERVICE_STRUCTURE",
    ),
  )
}

///|
test "invalid/envelope/empty trailer reference" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A:UN'UNT+2+'UNZ+1+I'"),
      "E_FIELD_REQUIRED",
    ),
  )
}

///|
test "invalid/envelope/functional group unsupported" {
  ignore(
    envelope_problem(
      envelope_case(b"UNG+A'UNH+1+ORDERS:D:96A:UN'UNT+2+1'UNE+1+A'UNZ+1+I'"),
      "E_GROUP_UNSUPPORTED",
    ),
  )
}

///|
test "invalid/envelope/second interchange unsupported" {
  ignore(
    envelope_problem(
      envelope_case(
        b"UNH+1+ORDERS:D:96A:UN'UNT+2+1'UNZ+1+I'UNB+UNOA:3+S+R+261011:1200+J'UNZ+0+J'",
      ),
      "E_TRAILING_SEGMENT",
    ),
  )
}

///|
test "invalid/envelope/missing message identifier component" {
  ignore(
    envelope_problem(
      envelope_case(b"UNH+1+ORDERS:D:96A'UNT+2+1'UNZ+1+I'"),
      "E_FIELD_REQUIRED",
    ),
  )
}

///|
test "invalid/envelope/no messages" {
  ignore(envelope_problem(envelope_case(b"UNZ+0+I'"), "E_MESSAGE_MISSING"))
}

///|
test "valid/envelope/standalone validator agrees with parse" {
  let r = @MoonEdifact.parse(
    envelope_case(b"UNH+1+ORDERS:D:96A:UN'UNT+9+1'UNZ+1+I'"),
  )
  let e = @MoonEdifact.validate_envelope(r.document.unwrap())
  assert_eq(e.diagnostics, r.diagnostics)
  assert_eq(e.interchange, r.interchange)
}

///|
test "invalid/envelope/long reference" {
  ignore(
    envelope_problem(
      envelope_case(
        b"UNH+123456789012345+ORDERS:D:96A:UN'UNT+2+123456789012345'UNZ+1+I'",
      ),
      "E_REFERENCE_INVALID",
    ),
  )
}
