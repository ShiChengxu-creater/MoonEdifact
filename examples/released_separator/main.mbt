///|
fn main {
  let result = @lib.parse(
    b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'FTX+A?+B?:C?'D??E'UNT+3+1'UNZ+1+I'",
  )
  println(@lib.report_text(result))
  if result.document is Some(doc) {
    let component = doc.segments[2].elements[0].components[0]
    println("logical=" + component.value.to_string())
    println(
      "raw_span=[" +
      component.span.start.to_string() +
      "," +
      component.span.end.to_string() +
      ")",
    )
    println("logical_bytes=" + component.value.length().to_string())
  }
}
