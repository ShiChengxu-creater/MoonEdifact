///|
fn main {
  let result = @lib.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'BGM+220+X'UNT+3+1'UNZ+1+I'",
  )
  println(@lib.report_text(result))
  if result.document is Some(doc) {
    println("first_tag=" + doc.segments[0].tag)
    println(
      "syntax_components=" +
      doc.segments[0].elements[0].components.length().to_string(),
    )
  }
}
