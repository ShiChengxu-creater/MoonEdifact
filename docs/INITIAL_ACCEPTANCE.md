# 0.1.0 初验记录

日期：2026-10-11。状态：本地实现和常规门禁通过，最后干净源码/包复验待记录。用户要求所有提交留在本地，由其自行 push；没有执行 push 或 Mooncakes publish。

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
| T8 文档/本地包与最终证据 | 完成后由最终提交记录关联 |

功能提交分别经本地合并进入 main，不 push。该表列实现提交，合并记录可从 `git log --first-parent main` 查阅。

## 最后复验

最终 Git 快照、干净源码测试与本地包结果将在此记录。输出写到 `_build/source-*/result.json`、`_build/consumer-*/result.json` 和 `_build/publish/check-result.json`；这些为本地构建证据，不随源码提交。

限制：本地运行环境为 Windows；Linux native 只配置待运行的 CI。没有业务目录验证、成熟工具黑盒对照、完整标准认证或性能/覆盖率百分比报告。规范页面存在直接访问限制，来源说明已披露。外部初验发布条件仍需维护者执行，不能仅凭本地结果宣布全部外部条件完成。
