# 第三方材料和依赖

| 名称 | 版本/来源 | 许可证 | 本项目用途与分发 |
|---|---|---|---|
| MoonBit core | 固定编译器发行 `0.10.14+7d59c7ec9` 携带的 core；[源仓库](https://github.com/moonbitlang/core) | Apache-2.0，已核对本机 core/LICENSE | builtin、buffer、debug、json、env、UTF-8 路径编码；以工具链依赖使用，不在源码包中复制 core |
| C/POSIX/Windows 平台库 | 本机编译器/操作系统 | 各平台自身条款 | 原创 native 适配调用标准文件 API，未拷入平台实现 |
| Python / Node.js / MoonBit 工具链 | 测试和构建环境 | 各工具自身条款 | 运行工具，不打包进 Mooncakes 源码 zip |
| UNECE 公开规范与 UNTDID | [来源记录](docs/PROVENANCE.md) | 原网站条件，不能视为本项目 Apache-2.0 资产 | 仅链接/协议行为依据，没有打包规范、目录或第三方样本 |

`moon.mod` 没有第三方 Mooncakes 包依赖。项目中的 `.mbt`、`cmd/nativeio/io.c`、Python 验证脚本、示例和合成语料是本次原创实现，采用根目录 Apache-2.0 LICENSE。已有仓库脚手架和 Copilot setup 工作流继续保留。

没有将 Smooks 或其他 EDIFACT 实现移植进项目。本次也没有执行其黑盒对照；后续引入材料必须先更新本表，并保留其许可证/NOTICE 要求。

`moon package` 的源码归档由 `scripts/package_checks.py` 核对 LICENSE、必需文档、核心/C 适配、语料摘要，并拒绝包含 Git、构建缓存、代理工作区和本地需求指令文件。
