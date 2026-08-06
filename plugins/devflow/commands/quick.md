---
name: devflow-quick
description: DevFlow 快速需求。把需求描述直接作为输入，跳过 PRD 填写阶段，立即完成分析并生成 spec/requirement.md。适合需求清晰的小功能、紧急修改、文案调整等场景。当用户说「devflow quick」「快速需求」「快速开始」或直接跟着需求描述时触发。
---

# devflow quick — 快速需求

**用途：** 将需求描述直接作为输入，跳过「创建 PRD → 填写 → 分析」三步，合并为一步完成。适合需求清晰、不需要反复确认 PRD 的场景。

**与 `devflow start` 的区别：**

| | `devflow start` | `devflow quick` |
|---|---|---|
| 适用场景 | 需求复杂，需要逐段补充 PRD | 需求清晰，一次说清 |
| 需求输入方式 | Intake Mode 逐段发送 | `$ARGUMENTS` 直接传入 |
| 产出 `01_initial_prd.md` | ✅ 有 | ❌ 跳过 |
| 产出 `spec/requirement.md` | Finalize 后生成 | **直接生成** |
| 后续流程 | 完全相同 | 完全相同 |

---

## 前置条件

- 若 `.devflow/` 不存在，自动触发 `devflow init` 后继续。
- `$ARGUMENTS` 不为空（必须附带需求描述）。

无描述时输出：
```
✗ 请在命令后附上需求描述。
  示例：devflow quick 修改登录页文案，「立即登录」改为「登录」
```

---

## 输入

`$ARGUMENTS` 直接传入需求描述，支持：
- 一句话描述：`devflow quick 添加分享按钮到详情页右上角`
- 多行描述（直接粘贴段落）
- 含 Figma 链接：`devflow quick 修改头像样式 https://figma.com/...`
- 含 YApi 链接：`devflow quick 接入新接口 https://yapi.hszq8.com/...`

---

## 执行步骤

### 1. 前置检查与自愈

检查 `.devflow/workspace.json`，不存在则自动执行 `devflow init`。

### 2. 创建工作项（无提示，静默完成）

从描述中推断：
- `type`：feature / bug / tech / refactor
- `slug`：英文驼峰，如 `ShareButton`
- `title`：中文简短标题

生成 ID：`{YYYYMMDD}-{slug}`，创建目录结构（同 `devflow start`）：

```
.devflow/work-items/{YYYYMMDD}-{slug}/
├── meta.json
├── context/
│   └── sanitized.md   ← 直接写入 $ARGUMENTS 内容（无 raw.md 脱敏步骤）
├── spec/
│   └── requirement.md ← 本命令结束时生成
├── tasks.md
├── progress.md
└── artifacts/
```

> **注意**：quick 场景需求描述简短且无敏感信息，`sanitized.md` 直接写入原始输入，不创建 `raw.md`。

更新 `workspace.json`：`currentWorkItem` 指向新工作项。

### 3. 立即识别并处理资源链接

扫描 `$ARGUMENTS` 中的链接，立即处理（无需等待用户触发）：

**Figma 链接**（含 `figma.com/design/` 或 `figma.com/file/`）：
- 使用 Figma Desktop MCP 立即读取（`get_figma_data` / `get_screenshot`）
- 提取页面层级、组件、交互状态、文案，写入后续生成的需求文档

**YApi / 接口链接**（含 `yapi.` 或 `/interface/api/`）：
- WebFetch 立即读取接口详情
- 提取字段定义、枚举值，写入后续生成的需求文档

**均无链接时**：进入步骤 4 的 CodeGraph 自动探查。

### 4. 分析与文档生成（一次性完成）

直接执行 `devflow analyze` 的 **Finalize 模式**逻辑，顺序：

1. **Figma 完整性检查**：发现 UI 改动但无设计稿 → 追问（同 analyze Finalize 步骤 1）
2. **CodeGraph 代码现状核验 + 现有接口反查**（同 analyze Finalize 步骤 3）
3. **补充歧义追问**：将识别到的歧义汇总后一次性提问（不像 Intake Mode 那样逐段打断），等用户回复后回写
4. **生成 `spec/requirement.md`**：输出完整需求文档

> **与 Intake Mode 的差异**：quick 不逐段打断追问，而是收集完所有歧义点后**汇总为一次提问**，用户回复后一次性写入文档。适合小需求节奏更快的场景。

### 5. 可选：同步到 Meegle

若 `workspace.json` 已配置 `meegle.projectKey`，询问是否同步创建 Meegle 工作项（同 `devflow start` 步骤 6）。

### 6. Context Checkpoint

写入 `progress.md`，更新 `meta.json`：`status → analyzing`，`stages.analyzed = true`。

---

## 输出

```
✅ 快速需求已创建并完成分析：{YYYYMMDD}-{slug}
  类型：{type}  标题：{title}
  Figma：{已读取 n 个节点 | 无}
  接口：{已读取 n 个接口 | CodeGraph 反查 n 个 | 无}
  歧义问题：{n} 个已确认 | 无歧义
  Meegle：{已同步 | 未配置}

已生成：spec/requirement.md

下一步：使用 `devflow design` 开始技术设计。
```
