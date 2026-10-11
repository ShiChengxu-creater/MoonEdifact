///|
fn main {
  match @nativeio.read_file("testdata/minimal.edi", max_bytes=8388608) {
    Err(_) => {
      @nativeio.stderr("Example file could not be read.")
      @nativeio.exit(2)
    }
    Ok(bytes) => {
      let result = @lib.parse(bytes)
      println("inspect=" + @lib.report_json(result))
      println("validate=" + @lib.report_text(result))
      println("exit=" + (if result.is_valid() { "0" } else { "1" }))
      if !result.is_valid() {
        @nativeio.exit(1)
      }
    }
  }
}
