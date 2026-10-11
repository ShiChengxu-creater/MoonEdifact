///|
priv struct DiagnosticSink {
  items : Array[Diagnostic]
  limit : Int
  mut exhausted : Bool
}

///|
fn DiagnosticSink::add(self : DiagnosticSink, error : Diagnostic) -> Unit {
  if self.exhausted {
    return
  }
  if self.items.length() < self.limit {
    self.items.push(error)
  } else {
    self.items[self.limit - 1] = diagnostic(
      "R_DIAGNOSTICS",
      Resource,
      error.span.start,
      error.span.end,
      "Diagnostic budget exhausted; validation stopped.",
      segment_index?=error.segment_index,
    )
    self.exhausted = true
  }
}

///|
fn DiagnosticSink::problem(
  self : DiagnosticSink,
  code : String,
  segment : Segment,
  span : SourceSpan,
  hint : String,
) -> Unit {
  self.add(
    diagnostic(
      code,
      Envelope,
      span.start,
      span.end,
      hint,
      segment_index=segment.index,
    ),
  )
}

///|
fn field_span(s : Segment, element : Int) -> SourceSpan {
  if element < s.elements.length() {
    s.elements[element].span
  } else {
    { start: s.span.end - 1, end: s.span.end - 1, }
  }
}

///|
fn mandatory_component(
  s : Segment,
  element : Int,
  component : Int,
  sink : DiagnosticSink,
) -> Bytes? {
  if element < s.elements.length() &&
    component < s.elements[element].components.length() {
    let c = s.elements[element].components[component]
    if !c.value.is_empty() {
      return Some(c.value)
    }
  }
  sink.problem(
    "E_FIELD_REQUIRED",
    s,
    field_span(s, element),
    "A mandatory service field is missing or empty.",
  )
  None
}

///|
fn mandatory_simple(
  s : Segment,
  element : Int,
  sink : DiagnosticSink,
) -> Bytes? {
  let value = mandatory_component(s, element, 0, sink)
  if element < s.elements.length() &&
    s.elements[element].components.length() != 1 {
    sink.problem(
      "E_SERVICE_STRUCTURE",
      s,
      field_span(s, element),
      "This service field must be a simple data element.",
    )
    return None
  }
  value
}

///|
fn reference_value(s : Segment, element : Int, sink : DiagnosticSink) -> Bytes? {
  let value = mandatory_simple(s, element, sink)
  if value is Some(bytes) && bytes.length() > 14 {
    sink.problem(
      "E_REFERENCE_INVALID",
      s,
      field_span(s, element),
      "Syntax 3 references must contain 1 to 14 characters.",
    )
    return None
  }
  value
}

///|
fn control_count(s : Segment, sink : DiagnosticSink) -> Int? {
  let value = mandatory_simple(s, 0, sink)
  match value {
    None => None
    Some(bytes) => {
      if bytes.length() > 6 {
        sink.problem(
          "E_COUNT_INVALID",
          s,
          field_span(s, 0),
          "Syntax 3 counts require 1 to 6 decimal digits.",
        )
        return None
      }
      let mut count = 0
      for b in bytes.iter() {
        if b < b'0' || b > b'9' {
          sink.problem(
            "E_COUNT_INVALID",
            s,
            field_span(s, 0),
            "Service count must contain decimal digits only.",
          )
          return None
        }
        count = count * 10 + (b.to_int() - 48)
      }
      Some(count)
    }
  }
}

///|
fn check_unb(s : Segment, sink : DiagnosticSink) -> Bytes? {
  for (e, c) in [(1, 0), (2, 0), (3, 0), (3, 1)] {
    ignore(mandatory_component(s, e, c, sink))
  }
  reference_value(s, 4, sink)
}

///|
fn check_unh(s : Segment, sink : DiagnosticSink) -> Bytes? {
  let reference = reference_value(s, 0, sink)
  for c = 0; c < 4; c = c + 1 {
    ignore(mandatory_component(s, 1, c, sink))
  }
  reference
}

///|
fn check_trailer(s : Segment, sink : DiagnosticSink) -> (Int?, Bytes?) {
  if s.elements.length() != 2 {
    sink.problem(
      "E_SERVICE_STRUCTURE",
      s,
      s.span,
      "A trailer must contain exactly a count and reference.",
    )
  }
  (control_count(s, sink), reference_value(s, 1, sink))
}

///|
/// Validate direct UNB/UNZ and UNH/UNT envelopes. Unknown business tags are preserved.
/// Groups, interactive envelopes and multiple interchanges are outside the 0.1.0 scope.
pub fn validate_envelope(
  document : Document,
  max_diagnostics? : Int = 100,
) -> EnvelopeResult {
  if max_diagnostics <= 0 {
    return {
      interchange: None,
      diagnostics: [
        diagnostic(
          "R_LIMITS_INVALID",
          Resource,
          0,
          0,
          "Diagnostic limit must be positive.",
        ),
      ],
      status: Failed,
    }
  }
  let sink : DiagnosticSink = {
    items: [],
    limit: max_diagnostics,
    exhausted: false,
  }
  let segments = document.segments
  if segments.is_empty() || segments[0].tag != "UNB" {
    sink.add(
      diagnostic(
        "E_UNB_MISSING",
        Envelope,
        document.span.start,
        document.span.start,
        "Interchange header UNB is missing.",
      ),
    )
    return { interchange: None, diagnostics: sink.items, status: Failed, }
  }
  let interchange_reference = check_unb(segments[0], sink)
  let messages : Array[Message] = []
  let seen : Map[Bytes, Bool] = Map([])
  let mut active : Int? = None
  let mut active_reference : Bytes? = None
  let mut message_headers = 0
  let mut closed = false
  for i = 1; i < segments.length(); i = i + 1 {
    if sink.exhausted {
      break
    }
    let s = segments[i]
    if closed {
      sink.problem(
        "E_TRAILING_SEGMENT",
        s,
        s.span,
        "Only one interchange is supported; segments after UNZ are rejected.",
      )
      continue
    }
    match s.tag {
      "UNH" => {
        if active is Some(_) {
          sink.problem(
            "E_UNT_MISSING",
            s,
            s.span,
            "A message header occurred before the previous message trailer.",
          )
        }
        active = Some(i)
        message_headers = message_headers + 1
        active_reference = check_unh(s, sink)
        if active_reference is Some(reference) {
          if seen.contains(reference) {
            sink.problem(
              "E_MESSAGE_REFERENCE_DUPLICATE",
              s,
              field_span(s, 0),
              "Message references must be unique within the interchange.",
            )
          }
          seen[reference] = true
        }
      }
      "UNT" => {
        let (count, reference) = check_trailer(s, sink)
        match active {
          None =>
            sink.problem(
              "E_UNH_MISSING",
              s,
              s.span,
              "Message trailer has no matching UNH.",
            )
          Some(first) => {
            if count is Some(n) && n != i - first + 1 {
              sink.problem(
                "E_MESSAGE_COUNT",
                s,
                field_span(s, 0),
                "UNT count must include UNH, business segments and UNT.",
              )
            }
            if reference is Some(r) && active_reference is Some(h) && r != h {
              sink.problem(
                "E_MESSAGE_REFERENCE",
                s,
                field_span(s, 1),
                "UNT reference does not match UNH.",
              )
            }
            messages.push({
              reference: active_reference.unwrap_or(b""),
              first_segment: first + 1,
              last_segment: i + 1,
              span: { start: segments[first].span.start, end: s.span.end, },
            })
            active = None
            active_reference = None
          }
        }
      }
      "UNZ" => {
        if active is Some(_) {
          sink.problem(
            "E_UNT_MISSING",
            s,
            s.span,
            "UNZ occurred before the message trailer.",
          )
          active = None
        }
        let (count, reference) = check_trailer(s, sink)
        if count is Some(n) && n != message_headers {
          sink.problem(
            "E_INTERCHANGE_COUNT",
            s,
            field_span(s, 0),
            "UNZ count must equal the number of direct message headers.",
          )
        }
        if reference is Some(r) && interchange_reference is Some(h) && r != h {
          sink.problem(
            "E_INTERCHANGE_REFERENCE",
            s,
            field_span(s, 1),
            "UNZ reference does not match UNB.",
          )
        }
        closed = true
      }
      "UNB" =>
        sink.problem(
          "E_UNB_NESTED",
          s,
          s.span,
          "Nested or repeated UNB is unsupported.",
        )
      "UNA" =>
        sink.problem(
          "E_UNA_POSITION",
          s,
          s.span,
          "UNA is only allowed before UNB.",
        )
      "UNG" | "UNE" =>
        sink.problem(
          "E_GROUP_UNSUPPORTED",
          s,
          s.span,
          "Functional groups are not supported in 0.1.0.",
        )
      "UIB" | "UIH" | "UIT" | "UIZ" =>
        sink.problem(
          "E_INTERACTIVE_UNSUPPORTED",
          s,
          s.span,
          "Interactive envelopes are not supported in 0.1.0.",
        )
      _ =>
        if active is None {
          sink.problem(
            "E_SEGMENT_OUTSIDE_MESSAGE",
            s,
            s.span,
            "Business segments must occur inside UNH/UNT.",
          )
        }
    }
  }
  if !sink.exhausted {
    if active is Some(first) {
      sink.problem(
        "E_UNT_MISSING",
        segments[first],
        { start: document.span.end, end: document.span.end, },
        "The message trailer UNT is missing.",
      )
    }
    if !closed {
      sink.add(
        diagnostic(
          "E_UNZ_MISSING",
          Envelope,
          document.span.end,
          document.span.end,
          "The interchange trailer UNZ is missing.",
        ),
      )
    }
    if message_headers == 0 {
      sink.add(
        diagnostic(
          "E_MESSAGE_MISSING",
          Envelope,
          document.span.start,
          document.span.end,
          "At least one direct message is required.",
        ),
      )
    }
  }
  {
    interchange: Some({ messages, span: document.span, }),
    diagnostics: sink.items,
    status: if sink.items.is_empty() {
      Passed
    } else {
      Failed
    },
  }
}
