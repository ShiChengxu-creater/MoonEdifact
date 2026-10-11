# 诊断与报告契约

`Diagnostic` 包含 `code`、`layer`、`severity`、`span`、可选 `segment_index`、`message` 和可选 `hint`。本版严重度均为 `error`，`hint` 预留且当前为 `None`；message 给出通用解释，不拼接输入字段。程序应依据 code/layer 判断，不依赖英文 message 的完整文本。

所有 span 是 0 起始原始字节 `[start,end)`；空范围是缺失字段或 EOF 处的定位。段序号从 1 起，UNA 不计入，无法分配段号时为 null。字段错误定位数据元范围，缺失数据元定位服务段终止符前；未闭合封套在文档末尾给出空范围。

## Syntax

| 代码 | 条件 |
|---|---|
| `S_UNA_TRUNCATED` | UNA 少于所需九个字节 |
| `S_SERVICE_INVALID` | 服务字符不是允许的 ASCII 标点 |
| `S_SERVICE_DUPLICATE` | 活动服务字符重复 |
| `S_DECIMAL_INVALID` | 小数符号不是点或逗号 |
| `S_UNA_RESERVED` | 版本 3 的 UNA 第 5 位不是空格 |
| `S_UNB_MISSING` | 起始位置没有 UNB |
| `S_SYNTAX_DECLARATION` | UNB 的语法声明缺失或结构错误 |
| `S_CHARSET_UNSUPPORTED` | 声明不是 UNOA/UNOB |
| `S_VERSION_UNSUPPORTED` | 声明版本不是 3 |
| `S_INTERACTIVE_UNSUPPORTED` | 第一服务段为交互式 UIB/UIH/UIT/UIZ |
| `S_TAG_INVALID` | 段标识不是恰好三个大写字母 |
| `S_CHARACTER_INVALID` | 值字节超出已声明配置的支持范围 |
| `S_RELEASE_INVALID` | release 后不是服务字符 |
| `S_RELEASE_TRUNCATED` | release 后没有字节 |
| `S_SEGMENT_UNTERMINATED` | 段没有完整标签/终止符 |

## Envelope

| 代码 | 条件 |
|---|---|
| `E_UNB_MISSING` | 独立封套检查中没有首段 UNB |
| `E_FIELD_REQUIRED` | 必需服务字段/组件缺失或为空 |
| `E_SERVICE_STRUCTURE` | 简单字段出现复合结构，或 trailer 元素数量错误 |
| `E_REFERENCE_INVALID` | 引用超过 14 字节 |
| `E_COUNT_INVALID` | 计数不是 1～6 个十进制数字 |
| `E_UNH_MISSING` | UNT 没有匹配的 UNH |
| `E_UNT_MISSING` | 新 UNH/UNZ 或 EOF 前缺少 UNT |
| `E_UNZ_MISSING` | 交换没有 UNZ |
| `E_MESSAGE_MISSING` | 交换没有直接消息头 |
| `E_MESSAGE_COUNT` | UNT 数量与 UNH 至 UNT 的实际段数不符 |
| `E_MESSAGE_REFERENCE` | UNT 引用与 UNH 不符 |
| `E_INTERCHANGE_COUNT` | UNZ 数量与直接 UNH 数量不符 |
| `E_INTERCHANGE_REFERENCE` | UNZ 引用与 UNB 不符 |
| `E_MESSAGE_REFERENCE_DUPLICATE` | 交换内消息引用重复 |
| `E_UNB_NESTED` | 封套闭合前再次遇到 UNB |
| `E_UNA_POSITION` | 段数组中再次遇到 UNA 标签 |
| `E_GROUP_UNSUPPORTED` | 遇到 UNG/UNE 功能组 |
| `E_INTERACTIVE_UNSUPPORTED` | 交换内部遇到交互式服务段 |
| `E_SEGMENT_OUTSIDE_MESSAGE` | 业务段出现在 UNH/UNT 之外 |
| `E_TRAILING_SEGMENT` | UNZ 后仍有非 CR/LF 段，包括第二个交换 |

若第二个 UNA 的原始格式无法构成普通段，扫描器可以先返回 syntax 错误；不保证对多重错误固定优先得到 unsupported 代码。

## Resource

| 代码 | 条件 |
|---|---|
| `R_LIMITS_INVALID` | 上限包含零/负数 |
| `R_INPUT_BYTES` | 输入/文件超过输入字节预算 |
| `R_SEGMENTS` | 超过最大段数 |
| `R_SEGMENT_BYTES` | 超过单段原始字节数，release 与终止符均计入 |
| `R_ELEMENTS` | 超过每段数据元数 |
| `R_COMPONENTS` | 超过每数据元组件数 |
| `R_DIAGNOSTICS` | 封套错误数量超过诊断预算，终止后续检查 |

语法/扫描错误立即返回一条诊断；封套错误按段顺序收集。恰好到诊断上限时保留已有代码；继续产生错误时，用 `R_DIAGNOSTICS` 替换最后一条，保持总数不超过上限。未返回的错误不表示通过。

库的输入超限诊断 span 为整个已提供输入；CLI 在读入前拒绝超大文件时无法提供完整输入区间，使用 `[0,0)`。

## JSON schema 1

`report_json(result)` 输出一个 JSON object，包含：

| 字段 | 值 |
|---|---|
| `schema_version` | 1 |
| `syntax` / `envelope` / `rules` | `passed`、`failed`、`not_checked` |
| `profile` | 版本、字符集、explicit_una、六个服务字符的整数 byte；无 Document 时为 null |
| `segment_count` / `message_count` | 返回模型的数量，失败时不是有效报文证明 |
| `segments` | index、tag、span、elements/components，组件逻辑 length |
| `messages` | first_segment、last_segment、span，不公开引用 |
| `diagnostics` | code、severity、layer、span、segment_index、message、hint |

默认组件不含 `value`。显式 `show_values=true` 为每个组件加入逻辑 ASCII value，包括发送/接收方和引用；这不等同于原始报文序列化。JSON 对特殊字符转义，对象字段顺序不作为消费契约。

扫描失败时 syntax=failed、envelope/rules=not_checked，两个模型为空；扫描通过后封套可以 failed。规则层在本版恒为 not_checked。文本报告采用相同的分层状态及代码/范围，不含字段原值。
