# 0.1.0 发布清单

初验实现阶段按用户要求先本地提交。2026-10-12 用户改为授权 Codex 创建公开 GitHub 仓库、推送并跟进 CI，失败时继续修复。GitHub 目标为 [ShiChengxu-creater/MoonEdifact](https://github.com/ShiChengxu-creater/MoonEdifact)；Mooncakes 发布和注册表安装仍未执行，本地源码包不等于注册表发布。

## 本地交付

- [x] 版本 0.1.0、Apache-2.0、README 与公开 API 文件。
- [x] 限定支持矩阵、诊断/安全/来源/AI 使用记录。
- [x] 三后端 check/build/test、五个示例、CLI 场景、独立消费项目。
- [x] 固定工具链 CI 与可复现脚本，没有自动发布。
- [x] 每个小目标本地提交，保留测试与实现关联。
- [x] 最后干净源码快照与本地 package 内容复验，证据见 INITIAL_ACCEPTANCE。

## GitHub 推送准备

- [x] 用 ShiChengxu-creater 创建公开仓库，origin 指向 `https://github.com/ShiChengxu-creater/MoonEdifact.git`。
- [x] 将 `moon.mod` 的 repository 设置为实际 URL；保留原 Mooncakes 包名。
- [ ] 发布前核对 Mooncakes 用户/包名可用性，GitHub 账号不代替注册表账号确认。
- [ ] 核对发布范围、维护联系、规范/许可记录和当前参赛轮次要求。
- [ ] 对元数据变更运行 `moon info`、`moon fmt`、check/test，提交并核对工作区。
- [ ] 按用户授权推送 main，并核对远程提交与本地 HEAD 一致。

## Push 后

- [ ] 记录 GitHub 公共仓库地址、提交 SHA 和三个 CI 任务成功链接；确认 Linux native 的实际结果。
- [ ] 运行 `moon package`、`python scripts/package_checks.py`，检查 `_build/publish/ShiChengxu-MoonEdifact-0.1.0.zip` 与 check-result.json。
- [ ] 登录经确认的 Mooncakes 账号，按维护者发布流程执行 `moon publish`；这是外部写操作，本次未运行。
- [ ] 记录 Mooncakes 0.1.0 页面、发布结果和对应 Git 提交，发布后创建维护者确认的版本标签。
- [ ] 在仓库之外新建干净消费项目，执行 `moon add ShiChengxu/MoonEdifact@0.1.0`，按 README 导入与运行；native/JS/wasm-gc 逐一验证。
- [ ] 更新注册表安装与外部发布证据，不把 workspace 消费成功当作注册表安装成功。

如果发布账号或仓库地址要求不同包名，须同时修改 moon.mod、所有包导入、消费者/包检查脚本和文档，并完整回归；不能只重命名压缩包。
