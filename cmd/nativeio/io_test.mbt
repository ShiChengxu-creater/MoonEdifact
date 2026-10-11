///|
test "valid/io/bounded file read" {
  let bytes = @nativeio.read_file("testdata/minimal.edi", max_bytes=1024).unwrap()
  assert_true(bytes.has_prefix(b"UNB+UNOA:3"))
  assert_true(bytes.length() < 1024)
}

///|
test "invalid/io/oversized file" {
  assert_eq(
    @nativeio.read_file("testdata/minimal.edi", max_bytes=12),
    Err(@nativeio.TooLarge),
  )
}

///|
test "invalid/io/missing file" {
  assert_eq(
    @nativeio.read_file("testdata/no-such-file.edi", max_bytes=1024),
    Err(@nativeio.IoFailure),
  )
}

///|
test "invalid/io/directory rejected" {
  assert_eq(
    @nativeio.read_file("testdata", max_bytes=1024),
    Err(@nativeio.IoFailure),
  )
}

///|
test "invalid/io/NUL path rejected" {
  assert_eq(
    @nativeio.read_file("testdata/minimal.edi\u0000extra", max_bytes=1024),
    Err(@nativeio.IoFailure),
  )
}

///|
test "invalid/io/nonpositive budget" {
  assert_eq(
    @nativeio.read_file("testdata/minimal.edi", max_bytes=0),
    Err(@nativeio.InvalidLimit),
  )
}
