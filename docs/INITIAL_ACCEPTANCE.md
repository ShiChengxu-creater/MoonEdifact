# 0.1.0 初验记录

日期：2026-10-11。状态：本地初验实现、文档、三后端门禁、干净源码、独立消费与本地包复验全部通过。用户要求所有提交留在本地，由其自行 push；没有执行 push 或 Mooncakes publish。

| goal.md 初验项 | 交付证据 |
|---|---|
| 语法版本 3、UNOA/UNOB、UNA | syntax.mbt / syntax_test.mbt；支持范围见 SYNTAX_PROFILES |
| release、空值、原始字节范围 | lexer.mbt / lexer_test.mbt，逻辑值与 raw span 断言 |
| 直接多消息服务封套 | envelope.mbt / envelope_test.mbt，计数/引用/顺序和 unsupported 路径 |
| 六种预算与稳定私密诊断 | api.mbt / limits_test.mbt / report_test.mbt，JSON schema 1 |
| native inspect/validate 与退出码 | cmd/main、cmd/options、cmd/nativeio；21 个实际进程场景 |
| 五个可运行示例 | examples/README.md、examples_smoke.py；native 五个，JS/wasm-gc 四个 |
| ≥60 测试、≥20 畸形、≥5 端到端 | native 109、JS/wasm-gc 各 103；54 个核心 invalid 用例；CLI 21 场景 |
| 格式、接口、三目标构建与测试 | fmt/check/build/test 通过，.mbti 差异审查；完整命令见 TESTING |
| README、CI、安全/来源/许可/AI 文档 | 根目录文档、docs、.github/workflows/ci.yml；源码主实现为 MoonBit |
| 独立可消费接口 | 从 Git archive 构造消费项目，每目标三个公开 API 测试通过 |
| 公共 Git、远程 CI、Mooncakes 发布及注册表安装 | 待维护者完成，见 RELEASE_CHECKLIST；不标记为通过 |

## 本地提交追踪

| 小目标 | 实现提交 |
|---|---|
| T0 基线与决策 | 92110e1 |
| T1 服务字符和版本 | 34f4e80 |
| T2 release/结构/源范围 | c2f7a6b |
| T3 服务封套 | 093e335 |
| T4 预算与报告 | f27a76e |
| T5 native CLI | da7aa56 |
| T6 示例与语料 | 0dda3be |
| T7 回归、独立消费与 CI | d371c84 |
| T8 文档与本地发布准备 | 003f02b |
| 干净复验：语料 LF 摘要修正 | 333fccb |
| 干净复验：打包目录隔离 | d09faa7 |

功能提交分别经本地合并进入 main，不 push。该表列实现提交，合并记录可从 `git log --first-parent main` 查阅。

## 最后复验

完整复验的 Git 快照为 `d09faa72a25cd7d5771b1f565b0bf1bf455e8ae7`。最后的证据提交只更新记录；实现、配置、语料和验证脚本与此快照一致。

| 验证 | 结果与本地证据 |
|---|---|
| 新源码目录的接口生成、格式、check/build/test | native 109/109、JS 103/103、wasm-gc 103/103；生成 .mbti 无漂移 |
| 新源码目录的示例 | native 5/5、JS 4/4、wasm-gc 4/4 |
| 新源码目录的真实 CLI | 21 个进程场景通过，另核对库与 CLI 同文件 JSON 相等 |
| 新源码目录的本地源码包 | 72 个文件验证通过，LICENSE/必需内容/五份语料摘要一致 |
| 新独立消费项目 | 三个目标各 3/3 个公开 API 测试通过，无注册表安装 |
| 核心畸形语料与源清单 | 54 个 invalid 用例、5 份 LF 语料摘要及定向凭证扫描通过 |

干净源码结果为 `_build/source-aou70h9k/result.json`，独立消费者为 `_build/consumer-z55c7i2b/result.json`。干净源码位于系统临时目录，具体位置在 source-path.txt，避免父仓库忽略规则影响打包。快照包 SHA-256 为 `40a2188df2c958331abea639677e3646bb5d5ae426fed698b68298c287fcdcd2`。

当前工作目录的最终包在 `_build/publish/ShiChengxu-MoonEdifact-0.1.0.zip`，摘要与内容核对结果在 `_build/publish/check-result.json`。证据文件和快照不随源码提交，发布前可用 TESTING 中脚本重跑。

复验发现并修复两项本地环境问题：四份语料的工作目录 CRLF 与 Git 内 LF 造成原摘要不匹配；源码快照置于父仓库 `_build` 会使打包器继承忽略规则。已分别改为 LF 摘要/索引核对和系统临时目录隔离，并从修正后的提交完整重跑。

限制：本地运行环境为 Windows；Linux native 只配置待运行的 CI。没有业务目录验证、成熟工具黑盒对照、完整标准认证或性能/覆盖率百分比报告。规范页面存在直接访问限制，来源说明已披露。外部初验发布条件仍需维护者执行，不能仅凭本地结果宣布全部外部条件完成。
