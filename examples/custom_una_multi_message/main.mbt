///|
fn main {
  let result = @lib.parse(
    b"UNA;*,! ~UNB*UNOA;3*S*R*261011;1200*I~UNH*1*ORDERS;D;96A;UN~FTX*A!*B~UNT*3*1~UNH*2*INVOIC;D;96A;UN~XYZ*X~UNT*3*2~UNZ*2*I~",
  )
  println(@lib.report_text(result))
  if result.document is Some(doc) {
    println(
      "component=" +
      doc.profile.component.to_int().to_string() +
      " element=" +
      doc.profile.element.to_int().to_string() +
      " terminator=" +
      doc.profile.terminator.to_int().to_string(),
    )
  }
  if result.interchange is Some(exchange) {
    for message in exchange.messages {
      println(
        "message_segments=" +
        message.first_segment.to_string() +
        ".." +
        message.last_segment.to_string(),
      )
    }
  }
}
