# 测试与复现

2026-10-11 本地环境为 Windows，MoonBit CLI `0.1.20260920 (914d7da 2026-09-20)`、编译器 `v0.10.14+7d59c7ec9 (2026-09-18)`、对应 moonrun；native 使用本机 C 编译器，JS 使用 Node.js。CI 固定同一 MoonBit 发行版本，在 Ubuntu 24.04 配置 native、JS、wasm-gc 三个独立任务。Linux native 的实际 CI 结果需 push 后记录。

## 用例清单

| 文件/包 | 测试数 | 覆盖 |
|---|---:|---|
| syntax_test.mbt | 18 | UNA、版本/字符集、服务字符冲突和 unsupported 路径 |
| lexer_test.mbt | 22 | 默认/自定义分隔符、release、空值、字节范围、异常终止 |
| envelope_test.mbt | 26 | 直接多消息、服务字段、计数、引用、顺序、功能组拒绝 |
| limits_test.mbt | 15 | 每种上限、恰好/超过预算、诊断预算停止 |
| report_test.mbt | 7 | JSON、状态分层、默认值/引用隐私、显式 opt-in |
| property_test.mbt | 2 | 固定种子转义变形与任意/突变字节安全性 |
| cmd/options | 13 | 参数、正整数溢出、用法和隐私开关 |
| cmd/nativeio | 6 | 普通文件读取、过大/不存在/目录/NUL 路径、非法预算 |
| 合计 | 109 native / 103 JS / 103 wasm-gc | JS/wasm-gc 排除 native I/O 包 |

解析核心含 54 个 `invalid/` 畸形/非法预算用例，高于初验 20 个下限；native 总数高于 60 个下限。`python scripts/repository_checks.py` 从实际测试声明统计数量，不把属性测试内部循环当作新增测试数。

`property_test.mbt` 使用固定 UInt LCG seed `0xED1FAC7`：64 个长度的服务字符转义后检查逻辑值和源范围；512 个任意字节/合法输入单字节突变检查有限终止、诊断/模型区间及可解析 JSON。无增量或序列化能力，未声称做 chunk 等价或 round-trip 测试。

## 端到端与语料

`python scripts/examples_smoke.py` 执行五个 native 示例并断言关键输出；JS/wasm-gc 各运行四个可移植示例。`python scripts/cli_smoke.py` 验证 21 次实际 CLI 进程调用，包括三种退出码、双消息/自定义服务字符、默认隐私、错误精确范围、Unicode 文件路径、超过 4 KiB 的多次读取、恰好/超过输入上限以及五份黄金语料；另比较同一文件的 CLI JSON 与库示例 JSON 完全相等。

五份 `testdata/*.edi` 均为本项目原创合成数据，生成约定、预期段/消息数、版本、字符集、诊断和 SHA-256 在 `manifest.json`。LF 固定为源码语料格式，避免 Windows checkout 改变偏移和摘要。没有真实交易信息或第三方目录数据。

## 本地命令

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
python scripts/examples_smoke.py --target native
python scripts/examples_smoke.py --target js
python scripts/examples_smoke.py --target wasm-gc
python scripts/cli_smoke.py
python scripts/clean_consumer.py
moon package
python scripts/package_checks.py
```

`clean_consumer.py` 的来源是 `git archive HEAD`，运行前应提交需要验证的修改。脚本建立新 workspace 和独立模块，三个目标各执行三个公开 API 用例；结果写到 `_build/consumer-*/result.json`。它不读取已有构建缓存、不安装已发布包，所有文件留在 `_build` 供核查。

`python scripts/clean_source.py` 可从当前提交的新源码目录重跑三后端门禁、示例与 CLI，结果在 `_build/source-*/result.json`。可用 `--target native` 或 `--ref COMMIT` 缩小/指定验证范围。两种快照验证均离线，不会 publish/push。

干净源码目录位于系统临时目录，避开父仓库 `_build/` 忽略规则对 `moon package` 的影响；`source-path.txt` 和 result.json 记录实际位置。快照与输出保留供核查，脚本不递归删除任何目录。黄金语料检查同时核对 LF、工作目录摘要和已有 Git 索引字节，避免换行转换掩盖问题。

接口由 `moon info` 生成，完成修改后运行 `moon info` 再 `moon fmt`，审查所有 `.mbti` 差异。稳定结果使用 assert_eq/assert_true；调试结构使用 Debug；当前测试不依赖更新 snapshot。

可选覆盖率命令为 `moon test --enable-coverage` 与 `moon coverage analyze`。本版未测量/公布覆盖率百分比或性能数字。`moon-audit` 未安装，已做定向凭证扫描和 AI 输入/FFI 逻辑审查；不能把这些等同于完整第三方安全审计。成熟解析器黑盒对照留待终验。

CI 保留既有 Copilot setup 工作流，新增 `ci.yml` 为初验门禁。工具链安装后会核对 moonc 版本；任务失败不会被改记为 skip/pass。工作流无自动发布及写权限。
