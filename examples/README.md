# 五个初验示例

从仓库根目录运行，要求 `moon 0.1.20260920` 及 native C 编译器。前四个示例也可加 `--target js` 或 `--target wasm-gc`；第五个文件读取示例只支持 native。

```sh
moon run examples/parse_minimal
moon run examples/custom_una_multi_message
moon run examples/released_separator
moon run examples/diagnose_bad_envelope
moon run examples/cli_inspect_validate
```

| 示例 | 可观察结果 |
|---|---|
| parse_minimal | `messages=1 segments=5`、`first_tag=UNB`、`syntax_components=2` |
| custom_una_multi_message | `messages=2 segments=8`；分隔符 byte 值 `59 / 42 / 126`；消息区间 `2..4` 和 `5..7` |
| released_separator | `logical=b"A+B:C'D?E"`；原文 `[55,68)`，逻辑长度 9 |
| diagnose_bad_envelope | `E_MESSAGE_COUNT [65,66)`、`E_MESSAGE_REFERENCE [67,72)`，`valid=false`；示例程序本身正常完成 |
| cli_inspect_validate | 读取 `testdata/minimal.edi`，打印 inspect JSON、validate 摘要和 `exit=0` |

相同文件的真实 CLI 命令与退出码：

```sh
moon run cmd/main -- inspect testdata/minimal.edi --json
moon run cmd/main -- validate testdata/minimal.edi
moon run cmd/main -- validate testdata/bad-count.edi
```

依次退出 0、0、1。失败报告包含 `E_MESSAGE_COUNT` 及错误字段的字节范围；业务规则始终 `not_checked`。本地 Windows native 构建后的程序路径为 `_build/native/debug/build/cmd/main/main.exe`，可复制或重命名使用。其他平台如果生成路径不同，可通过 `cli_smoke.py --exe PATH` 指定。

```sh
python scripts/examples_smoke.py
python scripts/cli_smoke.py
```

示例与语料全部由项目自行合成，未包含业务目录。来源、SHA-256 和预期结构见 `testdata/manifest.json`。
