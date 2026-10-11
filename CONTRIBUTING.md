# 贡献与维护

修改前阅读 README、SCOPE、SYNTAX_PROFILES 和 DIAGNOSTICS，明确变更属于语法、封套、报告还是 I/O。终验能力需先扩展支持矩阵和规范依据，不把未知格式静默当作已支持。

1. 在 `codex/` 或维护者指定的功能分支工作，每个可验收目标使用有意义的提交。
2. 为协议/错误处理修改先构造会失败的断言测试，修复后执行受影响测试和目标门禁。纯文档/格式修订不机械增加测试。
3. MoonBit 按 `///|` 分块，稳定结果使用 assert_eq/assert_true，结构调试使用 Debug。不要引入仅用于调试的 Show。
4. 修改后先 `moon info` 再 `moon fmt`，审查生成 `.mbti` 的公共差异；运行 [TESTING.md](docs/TESTING.md) 中适用命令。
5. 新样本使用原创合成数据，更新 manifest SHA-256、预期结构、诊断和来源；避免真实业务数据进入代码/日志。
6. 更新诊断/支持/变更记录。`0.x` 的破坏性 API 变化应明确记录；`1.0` 稳定契约需另行决定。

仓库提供可选 `.githooks`：pre-commit 运行定向凭证/语料检查、格式和类型检查；commit-msg 要求 Conventional Commits（合并提交豁免）；pre-push 跑三个目标测试。启用方式：

```sh
git config core.hooksPath .githooks
```

hooks 不自动 stage 文件或改写提交，修改接口需手动审查。没有启用 hooks 时仍应运行相同门禁；CI 另核对生成接口、构建和端到端结果。

提议在 GitHub 配置 main 分支保护：要求初验三个目标成功、禁止 force push、按维护团队规模要求审查。这些是建议，当前本地工作未配置远程保护。

安全问题优先通过仓库维护者可用的私下渠道提交最小合成复现；不公开真实报文或凭证。当前尚未设置公共仓库地址，发布前应补齐维护联系与 repository 字段。发布流程见 [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)，不要把 `moon package` 当作 publish。
