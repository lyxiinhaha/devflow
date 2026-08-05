---
name: devflow-init
description: DevFlow 工作区初始化。检查并配置 CodeGraph 与 Meegle，建立 .devflow/ 目录结构，确认安全分级，强制写入 .gitignore。当用户说「初始化 devflow」「devflow init」「初始化工作流」或在新项目首次使用 DevFlow 时触发。
---

# devflow init — 初始化工作区

**用途：** 在当前项目首次使用 DevFlow，建立 `.devflow/` 目录结构，配置 CodeGraph 与 Meegle，写入 `.gitignore`，确认安全分级。同一项目只需执行一次；`devflow start` 检测到未初始化时会自动触发本命令。

---

## 前置条件

- 必须在项目根目录执行。若当前目录不是根目录（无 README、构建配置文件、包管理文件或源码目录），必须提示用户切换目录后再继续，不得猜测。

---

## 执行步骤

### 1. 根目录校验

基于以下任一特征判断是否为项目根目录：README.md、package.json、build.gradle、Cargo.toml、pom.xml、Makefile、src/ 目录存在。

不满足时输出：
```
✗ 当前目录不像项目根目录。
  请切换到项目根目录后重新执行 devflow init。
```

### 2. 检查 CodeGraph

```bash
codegraph --version
```

- **已安装**：执行 `codegraph install` 注册 MCP，再执行 `codegraph init -i` 建立索引。
  - 大型项目（源码文件 > 500 个）：后台运行 `codegraph init -i`，在输出中注明"CodeGraph 索引已在后台执行"，不阻塞后续流程。
  - 执行 `codegraph status` 验证。
- **未安装**：`npm install -g @colbymchenry/codegraph`，安装后同上。
- **用户明确跳过**：不执行任何 CodeGraph 命令（install / init / sync / status 全部跳过）。
- **安全禁令**：不得修改项目中已存在的 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 等 AI 配置文件。

### 3. 检查 Meegle

```bash
meegle --version
```

- **已安装**：`meegle auth status` 验证授权；已授权则继续，未授权则 `meegle auth login`。
- **未安装**：提示用户安装 Meegle CLI 并授权；Meegle 为可选能力，用户跳过不影响后续流程。
- 授权成功后 `meegle user me` 验证连通性，输出当前用户名。

### 4. 建立 `.devflow/` 目录结构

将插件包 `assets/config/` 文件复制到 `.devflow/config/`，`assets/templates/` 复制到 `.devflow/config/templates/`。

```
.devflow/
├── workspace.json            ← 从 assets/config/workspace.tpl.json 生成
├── config/
│   ├── devflow.json          ← 状态机配置
│   ├── ai-policy.json        ← AI 安全策略
│   ├── repo-classification.json
│   └── templates/
│       ├── requirement.tpl.md
│       ├── design.tpl.md
│       ├── tasks.tpl.md
│       ├── progress.tpl.md
│       ├── meta.tpl.json
│       └── knowledge/
│           └── bug-experience-cards.csv
├── work-items/
└── doc/
    ├── architecture/
    ├── conventions/
    ├── ai/
    └── adr/
```

初始化 `workspace.json`：
```json
{
  "currentWorkItem": null,
  "meegle": {
    "projectKey": null,
    "defaultWorkItemType": null
  }
}
```

### 5. 写入 `.gitignore`

检查 `.gitignore`，若不存在则创建。确保以下条目存在（不重复写入）：

```gitignore
# DevFlow workspace (local only)
.devflow/

# CodeGraph index (local only)
.codegraph/
```

### 6. 交互式配置

1. **安全分级确认**：展示 `repo-classification.json` 的 L0/L1/L2 分级默认值，请求用户确认当前项目级别并写入。
2. **Meegle 空间配置**（可选）：询问是否有关联的 Meegle 项目空间名称。若有，执行 `meegle project search --project-key <名称>` 获取 `project_key` 并写入 `workspace.json`。

---

## 禁令

- ❌ 禁止修改已存在的 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 等 AI 配置文件
- ❌ 用户跳过 CodeGraph 时，禁止执行任何 CodeGraph 命令
- ❌ 禁止在非项目根目录执行初始化

---

## 输出

```
✅ DevFlow 初始化完成！
  根目录：{path}
  CodeGraph：{已建立索引 | 后台执行中 | 已跳过}
  Meegle：{已连接（用户：xxx）| 未配置}
  安全分级：{L0 | L1 | L2}
  Meegle 空间：{project_key | 未配置}
  .gitignore：已更新

现在可以使用 `devflow start` 创建第一个需求，或 `devflow fix` 修复 Bug。
```
