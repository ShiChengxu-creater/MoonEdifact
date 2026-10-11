# MoonEDIFACT

MoonBit 的 UN/EDIFACT 字节解析与封套检查库，附 native 文件 CLI。`0.1.0` 初验版支持语法版本 3、默认/自定义 `UNA`、release 转义和单交换中的多条直接消息，返回通用模型、原始字节范围和稳定诊断。

结果分别报告 `syntax`、`envelope`、`rules`。本版业务规则始终为 `not_checked`；`is_valid()` 只表示语法和封套通过。未知业务段会保留在模型中，ORDERS、INVOIC 等消息的业务顺序、代码表和伙伴规则需由调用者处理。

## 支持矩阵

| 能力 | 0.1.0 状态 |
|---|---|
| 语法版本 3；UNOA 限定字符；UNOB 可打印 ASCII 子集 | 支持 |
| UNA 或默认 `: + . ? 空格 '`；自定义服务字符 | 支持 |
| 转义、空元素/组件、原始半开字节范围 | 支持 |
| 单交换中的直接单/多消息，UNB/UNZ、UNH/UNT 顺序、引用及计数 | 支持 |
| 核心库 native / JavaScript / wasm-gc | 本地三个目标验证通过 |
| 文件 CLI | native；Windows 已验证，Linux 由提交后的 CI 验证 |
| 语法版本 4、功能组、交互式报文、连续交换 | 明确拒绝 |
| UTF-8/非 ASCII 值、完整业务目录、业务规则、增量解析、序列化 | 未实现 |

准确字符范围和服务字段检查边界见 [语法配置](docs/SYNTAX_PROFILES.md)；本版不声明完整 ISO 9735 或业务目录合规。

## 从源码运行

已验证工具链：`moon 0.1.20260920 (914d7da)`、`moonc v0.10.14+7d59c7ec9`。CI 使用官方安装器的固定发行参数 `0.10.14+7d59c7ec9`。native 需要可用的 C 编译器；JS 需要 Node.js；wasm-gc 使用工具链中的 moonrun。辅助验收脚本需要 Python 3.12 或更新版本，只使用标准库。

安装 MoonBit 的入口是 [官方下载页](https://www.moonbitlang.com/download)。取得本仓库源码后，在仓库根目录执行：

```sh
moon check --deny-warn
moon test --deny-warn
moon build --target native --deny-warn
moon run examples/parse_minimal
moon run cmd/main -- inspect testdata/minimal.edi --json
moon run cmd/main -- validate testdata/minimal.edi
```

验证成功的文本输出：

```text
syntax=passed envelope=passed rules=not_checked messages=1 segments=5
```

五个可运行示例、预期输出和目标限制见 [examples/README.md](examples/README.md)。`python scripts/cli_smoke.py` 检查实际二进制与库的输出一致。

## 嵌入 MoonBit 项目

包名沿用 `ShiChengxu/MoonEdifact`，版本 `0.1.0`。注册表发布尚未执行。**发布后**可在消费项目中执行：

```sh
moon add ShiChengxu/MoonEdifact@0.1.0
```

在消费包的 `moon.pkg` 添加：

```moonbit
import {
  "ShiChengxu/MoonEdifact" @edifact,
}
```

调用示例：

```moonbit
///|
fn main {
  let input = b"UNB+UNOA:3+S+R+261011:1200+I'UNH+1+ORDERS:D:96A:UN'BGM+220+X'UNT+3+1'UNZ+1+I'"
  let limits = { ..@edifact.default_limits(), max_input_bytes: 1048576, }
  let result = @edifact.parse(input, limits~)
  println(@edifact.report_text(result))
  if result.document is Some(doc) {
    println(doc.segments[0].tag)
  }
}
```

公开接口包括 `parse`、`detect_syntax`、`validate_envelope`、`default_limits`、`report_json`、`report_text` 与 `ParseResult::is_valid`；完整签名见 [pkg.generated.mbti](pkg.generated.mbti)。推荐通过 `parse` 接收不可信字节；独立 `validate_envelope` 面向已解析、保持模型不变量的 `Document`。

`Component.value` 是去除 release 后的 `Bytes`；`Component.span` 仍对应原始值字节。所有范围为从 0 开始的 `[start,end)`；段序号从 1 开始，UNA 不计作段。消息的 `first_segment`、`last_segment` 均包含边界服务段。

发布前可执行 `python scripts/clean_consumer.py`，从当前 Git 提交创建无构建缓存的独立消费项目，在三个目标测试公开 API。它使用本地 workspace 依赖，不能替代 Mooncakes 注册表安装证明。

## CLI 与输入限制

native 构建产物在本地 Windows 为 `_build/native/debug/build/cmd/main/main.exe`，可复制或重命名为 `moonedifact.exe`：

```sh
moonedifact inspect file.edi --json
moonedifact validate file.edi
moonedifact validate file.edi --json --max-bytes 1048576
moonedifact inspect file.edi --json --show-values
```

| 参数 | ParseLimits 字段 | 默认上限 |
|---|---|---:|
| `--max-bytes` | `max_input_bytes` | 8,388,608 字节 |
| `--max-segments` | `max_segments` | 100,000 段 |
| `--max-segment-bytes` | `max_segment_bytes` | 65,536 原始字节，含终止符 |
| `--max-elements` | `max_elements` | 每段 1,024 个数据元 |
| `--max-components` | `max_components` | 每数据元 128 个组件 |
| `--max-diagnostics` | `max_diagnostics` | 100 条诊断 |

所有上限必须是正的 32 位十进制整数。输入仅接受单个普通文件；使用 `--` 可传入以短横线开头的文件名。CLI 先检查文件大小，再以至多 4 KiB 的读取缓冲累计到预算，文件变大也不能绕过输入上限。解析仍构建完整 AST，内存会随输入和结构数量增长。

| 退出码 | 含义 |
|---|---|
| 0 | 语法/封套通过，或 help/version 正常完成 |
| 1 | 报文语法、封套或资源上限错误 |
| 2 | 参数、文件打开/读取等 I/O 错误 |

报告写 stdout，用法/I/O 错误写 stderr。默认 JSON 仅含结构、长度、位置和诊断，省略值和引用；`--show-values` 必须同时指定 `--json`，会公开全部逻辑值。结构信息也可能敏感，见 [安全说明](docs/SECURITY.md)。

典型错误：`E_MESSAGE_COUNT` 表示 UNT 段数错误，计数含 UNH 与 UNT；`E_MESSAGE_REFERENCE` 表示 UNT 与 UNH 引用不一致；`S_VERSION_UNSUPPORTED` 拒绝版本 4；`R_INPUT_BYTES` 表示输入超过预算。完整代码表及 JSON 契约见 [诊断说明](docs/DIAGNOSTICS.md)。

## 验证与文档

```sh
moon info
moon fmt
moon fmt --check
moon check --target native --deny-warn
moon build --target native --deny-warn
moon test --target native --deny-warn
moon check --target js --deny-warn
moon build --target js --deny-warn
moon test --target js --deny-warn
moon check --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
python scripts/repository_checks.py
python scripts/examples_smoke.py
python scripts/cli_smoke.py
python scripts/clean_consumer.py
moon package
python scripts/package_checks.py
```

测试数量、环境、畸形语料及属性测试方法见 [测试说明](docs/TESTING.md)。CI 在 push、PR 或手动运行时执行相同检查；不配置自动发布。初验进度与待维护者完成的远程步骤见 [初验记录](docs/INITIAL_ACCEPTANCE.md) 和 [发布清单](docs/RELEASE_CHECKLIST.md)。

实现采用 Apache-2.0：[LICENSE](LICENSE)。规范、原创测试数据和工具链依赖的边界见 [来源](docs/PROVENANCE.md)、[第三方材料](THIRD_PARTY.md)；AI 辅助范围见 [AI_USAGE.md](AI_USAGE.md)。贡献流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。
