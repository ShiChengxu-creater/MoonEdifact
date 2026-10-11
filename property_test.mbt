///|
test "edge/property/fixed seed release transformations" {
  // LCG seed is fixed; arithmetic intentionally wraps UInt modulo 2^32.
  let mut seed = 0xED1FAC7U
  let alphabet = b"AB +:'?.,"
  for length = 0; length < 64; length = length + 1 {
    let logical = @buffer.Buffer()
    let encoded = @buffer.Buffer()
    for i = 0; i < length; i = i + 1 {
      seed = seed * 1664525U + 1013904223U
      let b = alphabet[(seed % alphabet.length().reinterpret_as_uint()).reinterpret_as_int()]
      logical.write_byte(b)
      if b == b'+' || b == b':' || b == b'\'' || b == b'?' || b == b'.' {
        encoded.write_byte(b'?')
      }
      encoded.write_byte(b)
    }
    let input = b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+" +
      encoded.to_bytes() +
      b"'UNT+3+1'UNZ+1+I'"
    let result = @MoonEdifact.parse(input)
    assert_true(result.is_valid())
    let component = result.document.unwrap().segments[2].elements[0].components[0]
    assert_eq(component.value, logical.to_bytes())
    assert_eq(component.span.end - component.span.start, encoded.length())
  }
}

///|
test "edge/property/fixed seed arbitrary bytes and mutations terminate" {
  let mut seed = 0xED1FAC7U
  let base = b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+ABC'UNT+3+1'UNZ+1+I'"
  for case = 0; case < 512; case = case + 1 {
    seed = seed * 1664525U + 1013904223U
    let input = if case % 2 == 0 {
      let bytes = @buffer.Buffer()
      let length = (seed & 63U).reinterpret_as_int()
      for i = 0; i < length; i = i + 1 {
        seed = seed * 1664525U + 1013904223U
        bytes.write_byte((seed & 255U).reinterpret_as_int().to_byte())
      }
      bytes.to_bytes()
    } else {
      let bytes = base.to_array()
      let pos = (seed % bytes.length().reinterpret_as_uint()).reinterpret_as_int()
      seed = seed * 1664525U + 1013904223U
      bytes[pos] = (seed & 255U).reinterpret_as_int().to_byte()
      Bytes::from_array(bytes)
    }
    let result = @MoonEdifact.parse(input)
    for d in result.diagnostics {
      assert_true(
        d.span.start >= 0 &&
        d.span.end >= d.span.start &&
        d.span.end <= input.length(),
      )
    }
    if result.document is Some(doc) {
      for s in doc.segments {
        assert_true(s.span.start >= 0 && s.span.end <= input.length())
        for e in s.elements {
          for c in e.components {
            assert_true(
              c.span.start >= e.span.start && c.span.end <= e.span.end,
            )
            assert_true(c.value.length() <= c.span.end - c.span.start)
          }
        }
      }
    }
    assert_true(@json.valid(@MoonEdifact.report_json(result)))
  }
}
