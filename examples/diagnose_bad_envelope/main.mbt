///|
fn main {
  let result = @lib.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'BGM+220+X'UNT+2+OTHER'UNZ+1+I'",
  )
  println(@lib.report_text(result))
  println("valid=" + result.is_valid().to_string())
}
