///|
fn value_byte_allowed(b : Byte, p : SyntaxProfile) -> Bool {
  if b < b' ' || b > b'~' {
    return false
  }
  if p.charset == "UNOB" {
    return true
  }
  (b >= b'A' && b <= b'Z') ||
  (b >= b'0' && b <= b'9') ||
  b == b' ' ||
  b == b'.' ||
  b == b',' ||
  b == b'-' ||
  b == b'(' ||
  b == b')' ||
  b == b'/' ||
  b == b'=' ||
  b == p.component ||
  b == p.element ||
  b == p.decimal ||
  b == p.release ||
  b == p.terminator
}

///|
fn released_byte(b : Byte, p : SyntaxProfile) -> Bool {
  b == p.component ||
  b == p.element ||
  b == p.decimal ||
  b == p.release ||
  b == p.terminator
}

///|
fn scan_segment(
  input : Bytes,
  start : Int,
  p : SyntaxProfile,
  limits : ParseLimits,
  index : Int,
) -> Result[(Segment, Int), Diagnostic] {
  let len = input.length()
  if len - start < 4 {
    return Err(
      diagnostic(
        "S_SEGMENT_UNTERMINATED",
        Syntax,
        start,
        len,
        "A segment requires a tag and terminator.",
        segment_index=index,
      ),
    )
  }
  for offset = 0; offset < 3; offset = offset + 1 {
    let b = input[start + offset]
    if b < b'A' || b > b'Z' {
      return Err(
        diagnostic(
          "S_TAG_INVALID",
          Syntax,
          start,
          start + 3,
          "Segment tags must have exactly three uppercase letters.",
          segment_index=index,
        ),
      )
    }
  }
  if input[start + 3] != p.element && input[start + 3] != p.terminator {
    return Err(
      diagnostic(
        "S_TAG_INVALID",
        Syntax,
        start,
        start + 4,
        "Expected a data separator or terminator after the tag.",
        segment_index=index,
      ),
    )
  }
  if limits.max_segment_bytes < 4 {
    return Err(
      diagnostic(
        "R_SEGMENT_BYTES",
        Resource,
        start,
        start + 4,
        "Segment exceeds the configured byte budget.",
        segment_index=index,
      ),
    )
  }
  let tag = ascii_text(input, start, start + 3)
  let elements : Array[Element] = []
  let mut pos = start + 3
  if input[pos] == p.terminator {
    return Ok(
      ({ tag, index, elements, span: { start, end: pos + 1, }, }, pos + 1),
    )
  }
  pos = pos + 1
  while pos <= len {
    if elements.length() >= limits.max_elements {
      return Err(
        diagnostic(
          "R_ELEMENTS",
          Resource,
          pos,
          pos,
          "Data element count exceeds the configured budget.",
          segment_index=index,
        ),
      )
    }
    let element_start = pos
    let components : Array[Component] = []
    let mut component_start = pos
    let mut value = @buffer.Buffer()
    while true {
      if pos >= len {
        return Err(
          diagnostic(
            "S_SEGMENT_UNTERMINATED",
            Syntax,
            start,
            len,
            "Segment terminator is missing.",
            segment_index=index,
          ),
        )
      }
      if pos - start >= limits.max_segment_bytes {
        return Err(
          diagnostic(
            "R_SEGMENT_BYTES",
            Resource,
            start,
            pos + 1,
            "Segment exceeds the configured byte budget.",
            segment_index=index,
          ),
        )
      }
      let b = input[pos]
      if b == p.release {
        if len - pos < 2 {
          return Err(
            diagnostic(
              "S_RELEASE_TRUNCATED",
              Syntax,
              pos,
              pos + 1,
              "Release character has no following byte.",
              segment_index=index,
            ),
          )
        }
        if pos + 1 - start >= limits.max_segment_bytes {
          return Err(
            diagnostic(
              "R_SEGMENT_BYTES",
              Resource,
              start,
              pos + 2,
              "Segment exceeds the configured byte budget.",
              segment_index=index,
            ),
          )
        }
        if !released_byte(input[pos + 1], p) {
          return Err(
            diagnostic(
              "S_RELEASE_INVALID",
              Syntax,
              pos,
              pos + 2,
              "Release must precede a service character.",
              segment_index=index,
            ),
          )
        }
        value.write_byte(input[pos + 1])
        pos = pos + 2
        continue
      }
      if b == p.component || b == p.element || b == p.terminator {
        if components.length() >= limits.max_components {
          return Err(
            diagnostic(
              "R_COMPONENTS",
              Resource,
              component_start,
              pos,
              "Component count exceeds the configured budget.",
              segment_index=index,
            ),
          )
        }
        components.push({
          value: value.to_bytes(),
          span: { start: component_start, end: pos, },
        })
        if b == p.component {
          pos = pos + 1
          if components.length() >= limits.max_components {
            return Err(
              diagnostic(
                "R_COMPONENTS",
                Resource,
                pos,
                pos,
                "Component count exceeds the configured budget.",
                segment_index=index,
              ),
            )
          }
          component_start = pos
          value = @buffer.Buffer()
          continue
        }
        elements.push({ components, span: { start: element_start, end: pos, }, })
        pos = pos + 1
        if b == p.terminator {
          return Ok(
            ({ tag, index, elements, span: { start, end: pos, }, }, pos),
          )
        }
        break
      }
      if !value_byte_allowed(b, p) {
        return Err(
          diagnostic(
            "S_CHARACTER_INVALID",
            Syntax,
            pos,
            pos + 1,
            "Byte is outside the supported character set.",
            segment_index=index,
          ),
        )
      }
      value.write_byte(b)
      pos = pos + 1
    }
  }
  Err(
    diagnostic(
      "S_SEGMENT_UNTERMINATED",
      Syntax,
      start,
      len,
      "Segment terminator is missing.",
      segment_index=index,
    ),
  )
}
