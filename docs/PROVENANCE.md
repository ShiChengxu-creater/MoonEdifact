# 实现与测试来源

本项目按公开规范独立编写 MoonBit 实现及薄 C 文件适配，未移植成熟 EDI 工具代码。协议依据、工具链和测试数据分开记录，不将规范文本或业务目录纳入本项目许可证。

| 材料 | 使用方式 | 再分发范围 |
|---|---|---|
| [UNECE 语法规则](https://unece.org/fileadmin/DAM/trade/edifact/untdid/d422_s.htm) | 服务字符、交换/消息层次和语法版本的公开依据 | 仅链接及概括，没有复制规范全文 |
| [UNECE 报文语法说明](https://unece.org/DAM/trade/untdid/texts/d423.htm) | release 行为、UNH/UNT 与消息段计数依据 | 未复制样本或目录 |
| [UNECE 服务结构资料](https://service.unece.org/trade/untdid/texts/d426_d.htm) | 服务字段存在、引用与计数的实现依据 | 未打包服务/业务目录原文 |
| [UNTDID 许可](https://service.unece.org/trade/untdid/license.htm) | 明确目录数据与原创代码的授权边界 | 不分发完整目录或改写目录 |
| [MoonBit 官方工具链文档](https://docs.moonbitlang.com/en/latest/toolchain/moon/index.html) | 包配置、目标、测试与格式命令 | 链接和项目自写配置 |
| [MoonBit workspace 文档](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html) | 离线独立消费项目 | 自写验证脚本 |
| testdata、内联测试与示例 | 自行生成，服务字段为 S/R/I 等合成标识 | 本项目 Apache-2.0 |

2026-10-11 核验中，部分 UNECE 页面直接访问返回 403；对应公开索引可检索语法资料，且保留原始链接供维护者复核。没有据此宣称全面规范认证。项目只承诺文档所列的限定配置和服务字段检查。

`testdata/manifest.json` 保存五份语料的摘要和预期结果，报告按原始 LF 字节核对。消息标识 ORDERS/D/96A/UN 用于服务头结构示例，不表示附带或验证 D.96A 业务目录。

[Smooks EDI Cartridge](https://github.com/smooks/smooks-edi-cartridge) 是 `goal.md` 中的后续行为对照候选。本次没有引入、复制或运行其代码，不将其输出作为初验验证证据。终验对照需要记录工具版本、双方支持范围、差异和规范判断。

新材料必须单独记录来源、版本、许可、使用范围与改动，真实业务报文需合法授权且脱敏后才能进入测试。包和依赖清单见 [THIRD_PARTY.md](../THIRD_PARTY.md)。
