---
name: devflow-init
description: DevFlow 工作区初始化。检查并配置 CodeGraph 与 Meegle，自动检测项目类型（Android 壳工程/iOS CocoaPods/KMP 多仓库等），生成 CodeGraph 多根目录查询规则，建立 .devflow/ 目录结构，确认安全分级。当用户说「初始化 devflow」「devflow init」「初始化工作流」或在新项目首次使用 DevFlow 时触发。
---

# devflow init — 初始化工作区

**用途：** 在当前项目首次使用 DevFlow，建立 `.devflow/` 目录结构，配置 CodeGraph 与 Meegle，**自动检测多仓库架构并生成 CodeGraph 多根目录查询规则**，写入 `.gitignore`，确认安全分级。同一项目只需执行一次；`devflow start` 检测到未初始化时会自动触发本命令。

---

## 前置条件

- 必须在项目根目录执行。若当前目录不是根目录（无 README、构建配置文件、包管理文件或源码目录），必须提示用户切换目录后再继续，不得猜测。

---

## 执行步骤

### 1. 根目录校验

基于以下任一特征判断是否为项目根目录：README.md、package.json、build.gradle、Cargo.toml、pom.xml、Makefile、Podfile、*.xcodeproj、src/ 目录存在。

不满足时输出：
```
✗ 当前目录不像项目根目录。
  请切换到项目根目录后重新执行 devflow init。
```

### 2. 项目类型检测与多仓库分析

**自动检测项目类型**，决定后续 CodeGraph 的索引策略：

#### Android / KMP 壳工程（含 submodules）

特征：`build.gradle` 或 `settings.gradle` 存在，且有 `submodules/` 目录或 `.gitmodules` 文件。

策略：**单根索引**，`codegraph init` 在壳工程根目录运行即可，submodules 目录下的代码会被统一索引进同一个图谱。

记录到 `workspace.json`：
```json
{
  "codegraph": {
    "strategy": "single-root",
    "roots": [{ "path": ".", "covers": "壳工程 + 所有 submodules" }]
  }
}
```

**pod update / submodule 更新后的处理**：索引可能过期，记录到 `devflow.json`：
```json
{
  "codegraph": {
    "rebuildTriggers": ["submodule update", "pod install", "pod update"]
  }
}
```

---

#### iOS CocoaPods 壳工程

特征：`Podfile` 存在，且 `Pods/` 目录下有大量 Pod 源码。

执行以下检测：

```bash
# 1. 统计 Pods/ 下的 Pod 数量
ls Pods/ | wc -l

# 2. 检查是否有本地 path 引用的 Pod
grep -E "pod.*:path\s*=>" Podfile | head -20

# 3. 列出所有本地 path Pod 的绝对路径
grep -E "pod.*:path\s*=>" Podfile | grep -oE "'[^']+'" | tail -n +2
```

**策略：多根索引**

- **壳工程根目录**：`codegraph init`，覆盖壳工程源码 + `Pods/` 下所有 Pod 源码
- **本地 path Pod（每一个）**：单独 `cd <pod-path> && codegraph init`，覆盖该 Pod 的本地最新源码

若检测到本地 path Pod，逐一询问用户是否也为其初始化索引：
```
检测到以下本地 path Pod：
  1. ../HSAccountKit  (pod 'HSAccountKit', :path => '../HSAccountKit')
  2. ../HSTradeKit    (pod 'HSTradeKit',   :path => '../HSTradeKit')

是否为它们各自初始化 CodeGraph 索引？（推荐：是）
```

记录到 `workspace.json`：
```json
{
  "codegraph": {
    "strategy": "multi-root",
    "roots": [
      {
        "path": ".",
        "covers": "壳工程源码 + Pods/ 下所有 Pod 源码",
        "rebuildOn": ["pod install", "pod update"]
      },
      {
        "path": "../HSAccountKit",
        "covers": "本地联调 Pod：HSAccountKit",
        "rebuildOn": ["本地修改后手动 sync"]
      }
    ],
    "queryGuide": "查组件内部调用链 → 先在 ../HSAccountKit 查；查全局影响（谁调用了该组件）→ 在壳工程根目录查"
  }
}
```

**pod install / pod update 后的处理**：`Pods/` 目录文件全部替换，自动同步可能漏掉删除的旧文件。在项目 `CLAUDE.md` / `AGENTS.md` 中追加提醒（若文件已存在则在末尾追加，不覆盖原内容）：
```markdown
## CodeGraph 维护规则

执行 pod install 或 pod update 后，必须重建壳工程索引：
  cd {壳工程根目录} && codegraph index

本地 path Pod 修改后，同步对应索引：
  cd {pod路径} && codegraph sync
```

---

#### 多仓库（无 submodule，完全独立的多个仓库）

特征：用户明确告知，或根目录存在 `.devflow/multi-repo.json`（上次配置留存）。

询问用户：
```
当前项目是否依赖其他本地仓库的源码（如共享库、平台层、基础组件）？
如果是，请提供其他仓库的本地路径（一行一个，直接回车跳过）：
```

用户输入后，为每个仓库单独执行 `codegraph init`，并生成多根目录查询规则。

---

#### 单仓库项目

特征：无 submodules、无 Podfile 本地 path 引用、无多仓库依赖。

策略：**单根索引**，在根目录 `codegraph init` 即可。

---

### 3. 执行 CodeGraph 索引

```bash
codegraph --version
```

- **已安装**：按步骤 2 确定的策略执行 `codegraph init`（各根目录依次执行）。
  - 源码文件 > 500 个的根目录：后台运行，不阻塞后续流程。
  - 执行 `codegraph install` 注册 MCP（仅需执行一次）。
  - 执行 `codegraph status` 验证。
- **未安装**：`npm install -g @colbymchenry/codegraph`，安装后同上。
- **用户明确跳过**：不执行任何 CodeGraph 命令。
- **安全禁令**：不得修改 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 已有内容（只能追加 CodeGraph 维护规则）。

### 4. 生成 CodeGraph 多根目录查询规则（CLAUDE.md 注入）

**这是多仓库场景的关键步骤。** 将查询规则写入当前项目的 `CLAUDE.md`（若不存在则创建），让后续所有 AI 会话都知道如何跨仓查询：

```markdown
## CodeGraph 多根目录查询规则

本项目采用{单根 | 多根}索引策略，索引分布如下：

{根据步骤 2 的检测结果动态生成，例如：}

- 壳工程：{绝对路径}（覆盖：壳工程源码 + Pods/ 源码）
- 本地 Pod HSAccountKit：{绝对路径}（覆盖：本地联调最新源码）

查询流程：
1. 查组件内部调用链 → cd 到组件目录执行 codegraph_explore / codegraph_impact
2. 查全局影响（谁调用了该组件）→ 在壳工程根目录执行 codegraph_impact
3. 跨仓查询时，将两次结果合并得出完整影响面

CodeGraph 索引维护：
- 执行 pod install / pod update 后：cd {壳工程} && codegraph index
- 本地 Pod 修改后：cd {pod路径} && codegraph sync
- submodule update 后：cd {壳工程} && codegraph index
```

### 5. 检查 Meegle

```bash
meegle --version
```

- **已安装**：`meegle auth status` 验证；已授权则继续，未授权则 `meegle auth login`。
- **未安装**：提示安装；Meegle 为可选，用户跳过不影响后续流程。
- 授权成功后 `meegle user me` 验证，输出当前用户名。

### 6. 建立 `.devflow/` 目录结构

将插件包 `assets/config/` 复制到 `.devflow/config/`，`assets/templates/` 复制到 `.devflow/config/templates/`。

初始化 `workspace.json`（合并步骤 2 生成的 codegraph 配置）：
```json
{
  "currentWorkItem": null,
  "meegle": {
    "projectKey": null,
    "defaultWorkItemType": null
  },
  "codegraph": {
    "strategy": "single-root | multi-root",
    "roots": [...],
    "queryGuide": "..."
  }
}
```

### 7. 写入 `.gitignore`

确保以下条目存在（不重复写入）：

```gitignore
# DevFlow workspace (local only)
.devflow/

# CodeGraph index (local only)
.codegraph/
```

### 8. 交互式配置

1. **安全分级确认**：展示默认值，请求用户确认并写入。
2. **Meegle 空间配置**（可选）：若有，执行 `meegle project search` 获取 `project_key` 写入 `workspace.json`。

---

## 禁令

- ❌ 禁止覆盖 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 已有内容，只能追加
- ❌ 用户跳过 CodeGraph 时，禁止执行任何 CodeGraph 命令
- ❌ 禁止在非项目根目录执行初始化

---

## 输出

```
✅ DevFlow 初始化完成！
  根目录：{path}
  项目类型：{Android 壳工程 + submodules | iOS CocoaPods | KMP 多仓库 | 单仓库}

  CodeGraph 索引策略：{单根 | 多根}
    {path1}：{已建立索引 | 后台执行中 | 已跳过}
    {path2}：{已建立索引 | 已跳过}（本地 Pod）
  多根查询规则：已写入 CLAUDE.md

  Meegle：{已连接（用户：xxx）| 未配置}
  安全分级：{L0 | L1 | L2}
  .gitignore：已更新

现在可以使用 `devflow start` 创建第一个需求，或 `devflow fix` 修复 Bug。
```
