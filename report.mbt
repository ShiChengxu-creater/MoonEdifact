///|
/// Deterministic JSON report. Logical field values require an explicit opt-in.
pub fn report_json(result : ParseResult, show_values? : Bool = false) -> String {
  let segments : Array[Json] = []
  let messages : Array[Json] = []
  let mut profile = Json::null()
  if result.document is Some(doc) {
    let p = doc.profile
    profile = Json::object(
      Map([
        ("version", p.version.to_json()),
        ("charset", p.charset.to_json()),
        ("explicit_una", p.explicit_una.to_json()),
        (
          "service_characters",
          Json::object(
            Map([
              ("component", p.component.to_int().to_json()),
              ("element", p.element.to_int().to_json()),
              ("decimal", p.decimal.to_int().to_json()),
              ("release", p.release.to_int().to_json()),
              ("reserved", p.reserved.to_int().to_json()),
              ("terminator", p.terminator.to_int().to_json()),
            ]),
          ),
        ),
      ]),
    )
    for s in doc.segments {
      let elements : Array[Json] = []
      for e in s.elements {
        let components : Array[Json] = []
        for c in e.components {
          let fields = Map([
            ("span", span_json(c.span)),
            ("length", c.value.length().to_json()),
          ])
          if show_values {
            fields["value"] = ascii_text(c.value, 0, c.value.length()).to_json()
          }
          components.push(Json::object(fields))
        }
        elements.push(
          Json::object(
            Map([
              ("span", span_json(e.span)),
              ("components", Json::array(components)),
            ]),
          ),
        )
      }
      segments.push(
        Json::object(
          Map([
            ("index", s.index.to_json()),
            ("tag", s.tag.to_json()),
            ("span", span_json(s.span)),
            ("elements", Json::array(elements)),
          ]),
        ),
      )
    }
  }
  if result.interchange is Some(exchange) {
    for m in exchange.messages {
      messages.push(
        Json::object(
          Map([
            ("first_segment", m.first_segment.to_json()),
            ("last_segment", m.last_segment.to_json()),
            ("span", span_json(m.span)),
          ]),
        ),
      )
    }
  }
  let diagnostics = result.diagnostics.map(d => {
    Json::object(
      Map([
        ("code", d.code.to_json()),
        ("severity", d.severity.to_json()),
        ("layer", layer_name(d.layer).to_json()),
        ("span", span_json(d.span)),
        ("segment_index", d.segment_index.to_json()),
        ("message", d.message.to_json()),
        ("hint", d.hint.to_json()),
      ]),
    )
  })
  let report = Json::object(
    Map([
      ("schema_version", (1).to_json()),
      ("syntax", @json.to_json(status_name(result.syntax))),
      ("envelope", status_name(result.envelope).to_json()),
      ("rules", status_name(result.rules).to_json()),
      ("profile", profile),
      ("segment_count", segments.length().to_json()),
      ("message_count", messages.length().to_json()),
      ("segments", Json::array(segments)),
      ("messages", Json::array(messages)),
      ("diagnostics", Json::array(diagnostics)),
    ]),
  )
  report.stringify()
}

///|
fn span_json(span : SourceSpan) -> Json {
  Json::object(
    Map([("start", span.start.to_json()), ("end", span.end.to_json())]),
  )
}

///|
fn status_name(status : CheckStatus) -> String {
  match status {
    Passed => "passed"
    Failed => "failed"
    NotChecked => "not_checked"
  }
}

///|
fn layer_name(layer : Layer) -> String {
  match layer {
    Syntax => "syntax"
    Envelope => "envelope"
    Resource => "resource"
  }
}

///|
/// A concise summary and source diagnostics, without logical input values.
pub fn report_text(result : ParseResult) -> String {
  let segments = match result.document {
    Some(d) => d.segments.length()
    None => 0
  }
  let messages = match result.interchange {
    Some(i) => i.messages.length()
    None => 0
  }
  let text = StringBuilder()
  text.write_string(
    "syntax=" +
    status_name(result.syntax) +
    " envelope=" +
    status_name(result.envelope) +
    " rules=" +
    status_name(result.rules) +
    " messages=" +
    messages.to_string() +
    " segments=" +
    segments.to_string(),
  )
  for d in result.diagnostics {
    text.write_string(
      "\n" +
      d.code +
      " [" +
      d.span.start.to_string() +
      "," +
      d.span.end.to_string() +
      ")",
    )
    if d.segment_index is Some(index) {
      text.write_string(" segment=" + index.to_string())
    }
    text.write_string(" " + d.message)
  }
  text.to_string()
}

///|
/// True only when syntax and service envelopes passed. This does not check business rules.
pub fn ParseResult::is_valid(self : ParseResult) -> Bool {
  self.syntax == Passed && self.envelope == Passed
}
