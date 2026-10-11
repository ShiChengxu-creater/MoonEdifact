///|
test "valid/report/default JSON hides business and reference values" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+SECRET+PRIVATE+261011:1200+TOKEN'UNH+REF1+ORDERS:D:96A:UN'FTX+CONFIDENTIAL'UNT+3+REF1'UNZ+1+TOKEN'",
  )
  let json = @MoonEdifact.report_json(r)
  assert_true(@json.valid(json))
  assert_false(json.contains("SECRET"))
  assert_false(json.contains("CONFIDENTIAL"))
  assert_false(json.contains("REF1"))
  assert_true(json.contains("not_checked"))
}

///|
test "valid/report/values require explicit opt in" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+CONFIDENTIAL'UNT+3+1'UNZ+1+I'",
  )
  let json = @MoonEdifact.report_json(r, show_values=true)
  assert_true(@json.valid(json))
  assert_true(json.contains("CONFIDENTIAL"))
}

///|
test "valid/report/JSON quotes and backslashes are escaped" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOB:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+A\\B\"C'UNT+3+1'UNZ+1+I'",
  )
  assert_true(r.is_valid())
  let json = @MoonEdifact.report_json(r, show_values=true)
  assert_true(@json.valid(json))
  assert_true(json.contains("A\\\\B\\\"C"))
}

///|
test "valid/report/syntax failure still produces valid report" {
  let r = @MoonEdifact.parse(b"")
  assert_false(r.is_valid())
  let json = @MoonEdifact.report_json(r)
  assert_true(@json.valid(json))
  assert_true(json.contains("S_UNB_MISSING"))
  assert_true(json.contains("\"severity\":\"error\""))
}

///|
test "valid/report/text summary is private and layered" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+SECRET+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+PRIVATE'UNT+3+1'UNZ+1+I'",
  )
  assert_eq(
    @MoonEdifact.report_text(r),
    "syntax=passed envelope=passed rules=not_checked messages=1 segments=5",
  )
}

///|
test "valid/report/deterministic model and JSON" {
  let input = b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'UNT+2+1'UNZ+1+I'"
  let first = @MoonEdifact.parse(input)
  let second = @MoonEdifact.parse(input)
  assert_eq(first, second)
  assert_eq(@MoonEdifact.report_json(first), @MoonEdifact.report_json(second))
}

///|
test "invalid/report/reference errors never echo field value" {
  let r = @MoonEdifact.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'UNT+2+SENSITIVE'UNZ+1+PRIVATE'",
  )
  assert_false(@MoonEdifact.report_text(r).contains("SENSITIVE"))
  assert_false(@MoonEdifact.report_json(r).contains("PRIVATE"))
  assert_true(@MoonEdifact.report_text(r).contains("E_MESSAGE_REFERENCE"))
}
