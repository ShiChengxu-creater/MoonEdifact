///|
/// Detect an optional UNA and the UNB syntax declaration. Only syntax 3 is supported.
pub fn detect_syntax(input : Bytes) -> Result[SyntaxProfile, Diagnostic] {
  let explicit_una = input.length() >= 3 &&
    input[0] == b'U' &&
    input[1] == b'N' &&
    input[2] == b'A'
  if explicit_una && input.length() < 9 {
    return Err(
      diagnostic(
        "S_UNA_TRUNCATED",
        Syntax,
        0,
        input.length(),
        "UNA requires exactly six service characters.",
      ),
    )
  }
  let component = if explicit_una { input[3] } else { b':' }
  let element = if explicit_una { input[4] } else { b'+' }
  let decimal = if explicit_una { input[5] } else { b'.' }
  let release = if explicit_una { input[6] } else { b'?' }
  let reserved = if explicit_una { input[7] } else { b' ' }
  let terminator = if explicit_una { input[8] } else { b'\'' }
  if reserved != b' ' {
    return Err(
      diagnostic(
        "S_UNA_RESERVED",
        Syntax,
        7,
        8,
        "Syntax 3 requires a space at UNA position 5.",
      ),
    )
  }
  let services = [component, element, decimal, release, terminator]
  let positions = [3, 4, 5, 6, 8]
  for i = 0; i < services.length(); i = i + 1 {
    let b = services[i]
    if b < b'!' ||
      b > b'~' ||
      (b >= b'0' && b <= b'9') ||
      (b >= b'A' && b <= b'Z') ||
      (b >= b'a' && b <= b'z') {
      return Err(
        diagnostic(
          "S_SERVICE_INVALID",
          Syntax,
          positions[i],
          positions[i] + 1,
          "Service characters must be distinct printable ASCII punctuation.",
        ),
      )
    }
    for j = 0; j < i; j = j + 1 {
      if services[j] == b {
        return Err(
          diagnostic(
            "S_SERVICE_DUPLICATE",
            Syntax,
            positions[i],
            positions[i] + 1,
            "Service characters must be distinct.",
          ),
        )
      }
    }
  }
  if decimal != b'.' && decimal != b',' {
    return Err(
      diagnostic(
        "S_DECIMAL_INVALID",
        Syntax,
        5,
        6,
        "The decimal mark must be dot or comma.",
      ),
    )
  }
  let mut body_start = if explicit_una { 9 } else { 0 }
  while body_start < input.length() &&
        (input[body_start] == b'\r' || input[body_start] == b'\n') {
    body_start = body_start + 1
  }
  if input.length() - body_start < 4 ||
    input[body_start] != b'U' ||
    input[body_start + 1] != b'N' ||
    input[body_start + 2] != b'B' ||
    input[body_start + 3] != element {
    return Err(
      diagnostic(
        "S_UNB_MISSING",
        Syntax,
        body_start,
        input.length().min(body_start + 4),
        "Expected UNB as the first segment.",
      ),
    )
  }
  let start = body_start + 4
  if input.length() - start < 7 ||
    input[start + 4] != component ||
    (input[start + 6] != element && input[start + 6] != terminator) {
    return Err(
      diagnostic(
        "S_SYNTAX_DECLARATION",
        Syntax,
        start,
        input.length().min(start + 7),
        "Expected a four-letter syntax identifier and one syntax version digit.",
      ),
    )
  }
  let name = ascii_text(input, start, start + 4)
  if name != "UNOA" && name != "UNOB" {
    return Err(
      diagnostic(
        "S_CHARSET_UNSUPPORTED",
        Syntax,
        start,
        start + 4,
        "Only UNOA and the printable ASCII subset of UNOB are supported.",
      ),
    )
  }
  if input[start + 5] != b'3' {
    return Err(
      diagnostic(
        "S_VERSION_UNSUPPORTED",
        Syntax,
        start + 5,
        start + 6,
        "Only syntax version 3 is supported.",
      ),
    )
  }
  Ok({
    component,
    element,
    decimal,
    release,
    reserved,
    terminator,
    charset: name,
    version: 3,
    explicit_una,
    body_start,
  })
}

///|
fn ascii_text(input : Bytes, start : Int, end : Int) -> String {
  let text = StringBuilder()
  for i = start; i < end; i = i + 1 {
    text.write_char(input[i].to_char())
  }
  text.to_string()
}
