///|
test "valid/syntax/default UNOA profile" {
  match @MoonEdifact.detect_syntax(b"UNB+UNOA:3+S+R+261011:1200+I'") {
    Ok(profile) => {
      assert_eq(profile.charset, "UNOA")
      assert_eq(profile.version, 3)
      assert_eq(profile.element, b'+')
      assert_eq(profile.body_start, 0)
      assert_false(profile.explicit_una)
    }
    Err(_) => fail("expected supported syntax")
  }
}

///|
fn syntax_error(
  input : Bytes,
  code : String,
  start : Int,
  end : Int,
) -> Unit raise {
  match @MoonEdifact.detect_syntax(input) {
    Ok(_) => fail("expected rejection")
    Err(error) => {
      assert_eq(error.code, code)
      assert_eq(error.span.start, start)
      assert_eq(error.span.end, end)
      assert_eq(error.layer, @MoonEdifact.Syntax)
    }
  }
}

///|
test "valid/syntax/default UNOB profile" {
  let p = @MoonEdifact.detect_syntax(b"UNB+UNOB:3+S+R+261011:1200+I'").unwrap()
  assert_eq(p.charset, "UNOB")
  assert_eq(p.terminator, b'\'')
}

///|
test "valid/syntax/custom UNA" {
  let p = @MoonEdifact.detect_syntax(b"UNA;*,! ~UNB*UNOA;3*S*R*261011;1200*I~").unwrap()
  assert_eq(p.component, b';')
  assert_eq(p.element, b'*')
  assert_eq(p.decimal, b',')
  assert_eq(p.release, b'!')
  assert_eq(p.terminator, b'~')
  assert_eq(p.body_start, 9)
  assert_true(p.explicit_una)
}

///|
test "valid/syntax/CRLF after UNA" {
  let p = @MoonEdifact.detect_syntax(b"UNA:+.? '\r\nUNB+UNOA:3+S'").unwrap()
  assert_eq(p.body_start, 11)
}

///|
test "invalid/syntax/empty input" {
  syntax_error(b"", "S_UNB_MISSING", 0, 0)
}

///|
test "invalid/syntax/truncated UNA" {
  syntax_error(b"UNA:+.", "S_UNA_TRUNCATED", 0, 6)
}

///|
test "invalid/syntax/nonspace reserved position" {
  syntax_error(b"UNA:+.?*'UNB+UNOA:3'", "S_UNA_RESERVED", 7, 8)
}

///|
test "invalid/syntax/duplicate active character" {
  syntax_error(b"UNA++.? 'UNB+UNOA+3'", "S_SERVICE_DUPLICATE", 4, 5)
}

///|
test "invalid/syntax/alphanumeric service character" {
  syntax_error(b"UNA:A.? 'UNB A'", "S_SERVICE_INVALID", 4, 5)
}

///|
test "invalid/syntax/space active character" {
  syntax_error(b"UNA: .? 'UNB A'", "S_SERVICE_INVALID", 4, 5)
}

///|
test "invalid/syntax/nondecimal punctuation" {
  syntax_error(b"UNA:+;? 'UNB+UNOA:3'", "S_DECIMAL_INVALID", 5, 6)
}

///|
test "invalid/syntax/version four" {
  syntax_error(b"UNB+UNOA:4+S'", "S_VERSION_UNSUPPORTED", 9, 10)
}

///|
test "invalid/syntax/unsupported charset" {
  syntax_error(b"UNB+UNOC:3+S'", "S_CHARSET_UNSUPPORTED", 4, 8)
}

///|
test "invalid/syntax/incomplete syntax declaration" {
  syntax_error(b"UNB+UNOA:3", "S_SYNTAX_DECLARATION", 4, 10)
}

///|
test "invalid/syntax/wrong first segment" {
  syntax_error(b"UNH+1+ORDERS:D:96A:UN'", "S_UNB_MISSING", 0, 4)
}

///|
test "edge/syntax/leading newline retains offsets" {
  let p = @MoonEdifact.detect_syntax(b"\nUNB+UNOA:3+S'").unwrap()
  assert_eq(p.body_start, 1)
}

///|
test "invalid/syntax/version four UNA repetition is unsupported" {
  syntax_error(b"UNA:+.?*'UNB+UNOA:4+S'", "S_VERSION_UNSUPPORTED", 18, 19)
}

///|
test "invalid/syntax/interactive interchange unsupported" {
  syntax_error(b"UIB+UNOA:3+S'", "S_INTERACTIVE_UNSUPPORTED", 0, 3)
}
