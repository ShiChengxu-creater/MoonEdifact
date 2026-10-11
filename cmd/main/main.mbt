///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let raw = @env.args()
  let args : Array[String] = []
  for i = 1; i < raw.length(); i = i + 1 {
    args.push(raw[i])
  }
  match @options.parse_args(args) {
    Err(error) => {
      @nativeio.stderr(error + "\n" + @options.help_text())
      @nativeio.exit(2)
    }
    Ok(options) =>
      match options.action {
        Help => println(@options.help_text())
        Version => println("MoonEDIFACT 0.1.0")
        Inspect | Validate =>
          match
            @nativeio.read_file(
              options.file,
              max_bytes=options.limits.max_input_bytes,
            ) {
            Err(TooLarge) => {
              let result : @lib.ParseResult = {
                document: None,
                interchange: None,
                diagnostics: [
                  {
                    code: "R_INPUT_BYTES",
                    severity: "error",
                    layer: @lib.Resource,
                    span: { start: 0, end: 0, },
                    segment_index: None,
                    message: "File exceeds the configured byte budget; input was not fully read.",
                    hint: None,
                  },
                ],
                syntax: @lib.Failed,
                envelope: @lib.NotChecked,
                rules: @lib.NotChecked,
              }
              println(
                if options.json {
                  @lib.report_json(result)
                } else {
                  @lib.report_text(result)
                },
              )
              @nativeio.exit(1)
            }
            Err(_) => {
              @nativeio.stderr(
                "I/O error: unable to read a regular input file.",
              )
              @nativeio.exit(2)
            }
            Ok(bytes) => {
              let result = @lib.parse(bytes, limits=options.limits)
              println(
                if options.json {
                  @lib.report_json(result, show_values=options.show_values)
                } else {
                  @lib.report_text(result)
                },
              )
              if !result.is_valid() {
                @nativeio.exit(1)
              }
            }
          }
      }
  }
}
