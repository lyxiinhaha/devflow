---
name: devflow-start
description: DevFlow 创建新工作项。支持 Feature / Bug / Tech 类型，初始化状态机，可选同步到 Meegle。当用户说「开始新需求」「创建工作项」「新建需求」「devflow start」或描述了一个新的功能/任务需要开始时触发。
---

# devflow start — 创建新工作项

**用途：** 创建新的 Feature / Bug / Tech / Refactor 工作项，初始化状态机，建立标准目录结构，然后进入**需求收集模式（Intake Mode）**，边接收需求边即时解析，可选同步到 Meegle。

---

## 前置条件

- 若 `.devflow/` 不存在或结构不完整，**自动触发 `devflow init`** 后再继续。
- 工作项名称必须使用**英文驼峰命名法**（CamelCase）。

---

## 输入

通过 `$ARGUMENTS` 传入，格式：
- `{类型} {标题} {描述}` — 例：`feature 用户头像上传 支持裁剪和预览`
- 直接描述，AI 推断类型并生成标题

---

## 执行步骤

### 1. 前置检查与自愈

检查 `.devflow/workspace.json` 是否存在，不存在则自动执行 `devflow init`。

### 2. 解析输入

提取：
- `type`：feature / bug / tech / refactor
- `slug`：英文驼峰，如 `UserAvatarUpload`
- `title`：中文简短标题
- 生成 ID：`{YYYYMMDD}-{slug}`

### 3. 创建本地目录结构

```
.devflow/work-items/{YYYYMMDD}-{slug}/
├── meta.json          ← 从 meta.tpl.json 生成并填充
├── context/
│   ├── raw.md         ← 写入用户原始输入（AI 后续禁止直接读取）
│   └── sanitized.md   ← 需求收集内容追加到此（AI 唯一输入源）
├── spec/
│   ├── requirement.md ← 从 requirement.tpl.md 生成，Intake Mode 中逐步填充
│   ├── design.md
│   └── api.md
├── tasks.md
├── progress.md
├── review.md
└── artifacts/         ← 图片、截图、附件存放于此
```

初始化 `meta.json`（status: `created`，`linkedMeegleId`: 空）。

将用户原始输入写入 `context/raw.md`；`context/sanitized.md` 初始为空，由 Intake Mode 逐步填充。

### 4. 更新 workspace.json

```json
{ "currentWorkItem": "{YYYYMMDD}-{slug}" }
```

### 5. 可选：同步到 Meegle

若 `workspace.json` 已配置 `meegle.projectKey`，询问是否同步创建 Meegle 工作项，返回 `linkedMeegleId` 写入 `meta.json`。

### 6. 进入需求收集模式（Intake Mode）

工作项创建完成后，**立即进入 Intake Mode**，后续每一条用户消息都视为需求输入，由 `devflow analyze` 的流式模式即时处理。

输出创建完成提示后，输出 Intake Mode 提示：

```
✅ 工作项已创建：{YYYYMMDD}-{slug}
  类型：{type}  安全分级：{L0|L1|L2}  Meegle：{ID|未同步}

📋 已进入需求收集模式
  现在请逐段发送需求内容，每段收到后立即解析：
  · 文字描述 → 立即提取功能点，发现歧义即时追问
  · Figma 链接 → 立即读取设计稿，与文字交叉核验
  · Apifox/YApi 链接 → 立即读取接口定义
  · 图片/截图 → 保存到 artifacts/，提取可见信息

  发送「就这些了」或「devflow analyze」完成收集，生成最终需求文档。
```

---

## 禁令

- ❌ 禁止 AI 在后续流程中读取 `context/raw.md`，只能读取 `context/sanitized.md`
- ❌ 工作项名称不得使用中文或特殊字符
