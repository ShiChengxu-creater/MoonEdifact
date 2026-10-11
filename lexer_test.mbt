///|
test "valid/lexer/structure and raw spans" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'BGM+220+X'UNT+3+1'UNZ+1+I'",
  )
  assert_eq(r.syntax, @MoonEdifact.Passed)
  let doc = r.document.unwrap()
  assert_eq(doc.segments.length(), 5)
  assert_eq(doc.segments[0].tag, "UNB")
  assert_eq(doc.segments[0].elements[0].components.length(), 2)
  assert_eq(doc.segments[0].elements[0].components[0].value, b"UNOA")
  assert_eq(doc.segments[0].elements[0].components[0].span.start, 4)
  assert_eq(doc.segments[0].elements[0].components[0].span.end, 8)
  assert_eq(doc.segments[0].span.end, 29)
}

///|
fn lexer_doc(body : Bytes) -> @MoonEdifact.Document raise {
  let input = @buffer.Buffer()
  input.write_bytes(b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'")
  input.write_bytes(body)
  input.write_bytes(b"UNT+3+1'UNZ+1+I'")
  let r = @MoonEdifact.parse(input.to_bytes())
  assert_eq(r.syntax, @MoonEdifact.Passed)
  r.document.unwrap()
}

///|
fn lexer_error(
  input : Bytes,
  code : String,
  start : Int,
  end : Int,
) -> Unit raise {
  let r = @MoonEdifact.parse(input)
  assert_eq(r.syntax, @MoonEdifact.Failed)
  assert_true(r.document is None)
  assert_eq(r.diagnostics.length(), 1)
  assert_eq(r.diagnostics[0].code, code)
  assert_eq(r.diagnostics[0].span.start, start)
  assert_eq(r.diagnostics[0].span.end, end)
  assert_eq(r.diagnostics[0].segment_index, Some(2))
}

///|
test "valid/lexer/released plus" {
  let s = lexer_doc(b"XYZ+A?+B'").segments[2]
  assert_eq(s.elements.length(), 1)
  assert_eq(s.elements[0].components[0].value, b"A+B")
  assert_eq(
    s.elements[0].components[0].span.end -
    s.elements[0].components[0].span.start,
    4,
  )
}

///|
test "valid/lexer/released component separator" {
  let s = lexer_doc(b"XYZ+A?:B'").segments[2]
  assert_eq(s.elements[0].components.length(), 1)
  assert_eq(s.elements[0].components[0].value, b"A:B")
}

///|
test "valid/lexer/released terminator" {
  let s = lexer_doc(b"XYZ+A?'B'").segments[2]
  assert_eq(s.elements[0].components[0].value, b"A'B")
  assert_eq(s.span.end - s.span.start, 9)
}

///|
test "valid/lexer/released release" {
  assert_eq(
    lexer_doc(b"XYZ+A??B'").segments[2].elements[0].components[0].value,
    b"A?B",
  )
}

///|
test "valid/lexer/released decimal mark" {
  assert_eq(
    lexer_doc(b"XYZ+1?.5'").segments[2].elements[0].components[0].value,
    b"1.5",
  )
}

///|
test "valid/lexer/combined release values" {
  let s = lexer_doc(b"FTX+AAI+++A?+B?:C?'D??E'").segments[2]
  assert_eq(s.elements.length(), 4)
  assert_eq(s.elements[3].components[0].value, b"A+B:C'D?E")
}

///|
test "valid/lexer/leading middle trailing empty elements" {
  let s = lexer_doc(b"XYZ++A++'").segments[2]
  assert_eq(s.elements.length(), 4)
  assert_eq(s.elements[0].components[0].value, b"")
  assert_eq(s.elements[1].components[0].value, b"A")
  assert_eq(s.elements[2].components[0].value, b"")
  assert_eq(s.elements[3].span.start, s.elements[3].span.end)
}

///|
test "valid/lexer/leading middle trailing empty components" {
  let s = lexer_doc(b"XYZ+:A::'").segments[2]
  assert_eq(s.elements.length(), 1)
  assert_eq(s.elements[0].components.length(), 4)
  assert_eq(s.elements[0].components[0].value, b"")
  assert_eq(s.elements[0].components[1].value, b"A")
  assert_eq(s.elements[0].components[2].value, b"")
  assert_eq(s.elements[0].components[3].value, b"")
}

///|
test "edge/lexer/missing element differs from empty element" {
  assert_eq(lexer_doc(b"XYZ'").segments[2].elements.length(), 0)
  assert_eq(lexer_doc(b"XYZ+'").segments[2].elements.length(), 1)
}

///|
test "valid/lexer/CRLF between segments only" {
  let doc = lexer_doc(b"\r\nXYZ+A'\r\n")
  assert_eq(doc.segments[2].index, 3)
  assert_eq(doc.segments[2].tag, "XYZ")
  assert_eq(doc.segments.length(), 5)
}

///|
test "valid/lexer/UNOB lowercase" {
  let r = @MoonEdifact.parse(b"UNB+UNOB:3+S'XYZ+abc'")
  assert_eq(r.syntax, @MoonEdifact.Passed)
  assert_eq(
    r.document.unwrap().segments[1].elements[0].components[0].value,
    b"abc",
  )
}

///|
test "valid/lexer/custom separators and release" {
  let r = @MoonEdifact.parse(
    b"UNA;*,! ~UNB*UNOA;3*S*R*261011;1200*I~XYZ*A!*B!;C!~D!!E~",
  )
  assert_eq(r.syntax, @MoonEdifact.Passed)
  let doc = r.document.unwrap()
  assert_eq(doc.span.start, 9)
  assert_eq(doc.segments[1].elements[0].components[0].value, b"A*B;C~D!E")
}

///|
test "invalid/lexer/lowercase UNOA value" {
  lexer_error(b"UNB+UNOA:3+S'XYZ+a'", "S_CHARACTER_INVALID", 17, 18)
}

///|
test "invalid/lexer/high byte" {
  lexer_error(b"UNB+UNOB:3+S'XYZ+\xff'", "S_CHARACTER_INVALID", 17, 18)
}

///|
test "invalid/lexer/release before ordinary letter" {
  lexer_error(b"UNB+UNOA:3+S'XYZ+?A'", "S_RELEASE_INVALID", 17, 19)
}

///|
test "invalid/lexer/truncated release" {
  lexer_error(b"UNB+UNOA:3+S'XYZ+A?", "S_RELEASE_TRUNCATED", 18, 19)
}

///|
test "invalid/lexer/unterminated segment" {
  lexer_error(b"UNB+UNOA:3+S'XYZ+A", "S_SEGMENT_UNTERMINATED", 13, 18)
}

///|
test "invalid/lexer/newline within value" {
  lexer_error(b"UNB+UNOA:3+S'XYZ+A\nB'", "S_CHARACTER_INVALID", 18, 19)
}

///|
test "invalid/lexer/lowercase tag" {
  lexer_error(b"UNB+UNOA:3+S'Xyz+A'", "S_TAG_INVALID", 13, 16)
}

///|
test "invalid/lexer/extended tag" {
  lexer_error(b"UNB+UNOA:3+S'XYZA+A'", "S_TAG_INVALID", 13, 17)
}

///|
test "invalid/lexer/escaped final terminator is data" {
  lexer_error(b"UNB+UNOA:3+S'XYZ+A?'", "S_SEGMENT_UNTERMINATED", 13, 20)
}
