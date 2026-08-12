# Changelog

## v3.2.0 — 2026-08-11

### Worktree 并行开发支持

#### `devflow code` — 默认 worktree 模式

编码阶段默认在独立 worktree 中进行，无需手动选择：

```bash
devflow code              # 默认，自动创建 worktree
devflow code noworktree   # 跳过 worktree，在当前工作区直接编码
```

创建 worktree 后自动执行 `worktree-setup.sh` 完成环境初始化，worktree 可直接构建真机包：

- **Android**：软链 `local.properties`（SDK 路径），`gradlew` 立即可用
- **iOS**：检查 path Pod 路径，执行 `pod install`，可直接 Xcode 打开

#### 新增 `skills/devflow-worktree-setup/worktree-setup.sh`

一键处理 worktree 的本地文件软链和环境初始化，不需要手动处理：

| 项目类型 | 自动处理内容 |
|---------|-----------|
| Android | 软链 `local.properties`、`keystore.properties`、`signing.properties` |
| iOS | 检测外部 path Pod 并警告，执行 `pod install` |

#### `devflow review` — 审查通过后选择合并/提 MR

审查通过（APPROVED）后提供 4 个选项（基于 `finishing-a-development-branch` skill）：

```
1. 合并到本地 <base-branch>
2. Push 并创建 MR/PR         ← MR body 自动填充改动说明、文件清单、验收清单链接
3. 保留分支（稍后处理）
4. 丢弃此次改动
```

BLOCKED / CHANGES REQUESTED 时不触发，修复后重跑 review。

---

### workspace.json 多工作项并行支持

`workspace.json` 结构升级，支持多个工作项同时进行：

```json
// 之前
{ "currentWorkItem": "20260811-UserAvatarUpload" }

// 之后
{
  "focus": "20260811-UserAvatarUpload",
  "activeWorkItems": [
    {
      "id": "20260811-UserAvatarUpload",
      "title": "用户头像上传",
      "status": "coding",
      "worktree": ".worktrees/UserAvatarUpload",
      "branch": "feature/20260811-UserAvatarUpload",
      "startedAt": "2026-08-11T10:00:00Z"
    },
    {
      "id": "20260810-PaymentRefactor",
      "title": "支付模块重构",
      "status": "designing",
      "worktree": ".worktrees/PaymentRefactor",
      "branch": "feature/20260810-PaymentRefactor",
      "startedAt": "2026-08-10T14:00:00Z"
    }
  ]
}
```

**各命令行为变化：**

| 命令 | 之前 | 之后 |
|------|------|------|
| `devflow code` | 切换 currentWorkItem | 追加到 activeWorkItems，不影响其他项 |
| `devflow switch` | 覆盖 currentWorkItem | 只切换 focus，其他项继续跑 |
| `devflow continue` | 恢复单个工作项 | 展示所有并行项，选焦点后恢复 |
| `devflow list` | 平铺所有工作项 | 活跃分组额外显示 worktree 路径和存在状态 |
| review 合并后 | 无感知 | 从 activeWorkItems 移除，focus 自动切到下一项 |

---

## v3.1.1 — 2026-08-11

### 新增 `devflow checklist` — 真机验收清单

基于 `spec/requirement.md` 和 `spec/design.md` 生成可直接交付测试人员的结构化清单：
- 自动识别是否有前端页面（按信号词检测），有则强制输出进入路径
- 判断前提条件复杂度，难以真实构造的状态自动生成 Mock 接口表格
- 每条 AC 对应具体可观测的检查点（不允许「正确展示」这类模糊表述）
- 清单末尾附回归验证表（结合 CodeGraph impact 识别影响范围）
- 优先读取项目配置的专项 skill（`project-acceptance-checklist` 等），降级到通用规范

查找路径（按优先级）：
```
{项目根}/.claude/skills/project-acceptance-checklist/
{项目根}/.ai/skills/project-acceptance-checklist/
~/.claude/skills/project-acceptance-checklist/
```

清单写入 `spec/acceptance-checklist.md`。

### `devflow review` 委托专项 skill

优先委托 `project-code-review-android` / `project-code-review-ios` 执行深度审查（平台特有的内存/并发/安全规则），降级通用四维度审查。

---

## v3.1.0 — 2026-08-10

### 多工程项目兼容

#### `devflow init` 新增项目类型检测

初始化时自动识别项目架构，生成对应的 CodeGraph 索引策略：

| 项目类型 | 索引策略 |
|---------|---------|
| Android / KMP 壳工程 + submodules | 单根索引，壳工程根目录一次 init，submodules 统一覆盖 |
| iOS CocoaPods（含本地 path Pod） | 多根索引，壳工程 + 每个本地 path Pod 各自 init |
| 完全独立多仓库 | 多根索引，用户提供各仓库路径后逐一 init |
| 单仓库 | 单根索引，无额外操作 |

检测逻辑：
- Android/KMP：识别 `build.gradle` + `.gitmodules` / `submodules/` 目录
- iOS：识别 `Podfile`，并 `grep -E "pod.*:path\s*=>"` 找出所有本地 path Pod
- 每个本地 path Pod 询问用户是否单独初始化索引

配置写入 `workspace.json`（`codegraph.strategy` / `codegraph.roots` / `codegraph.moduleRootMap`），多根查询规则自动注入 `CLAUDE.md`，后续会话无需手动声明。

#### 新增 `devflow-cg` 脚本

`skills/devflow-cg/devflow-cg.sh`，将多根路由、新鲜度检查从 LLM 推理移到脚本执行：

```bash
devflow-cg explore "<query>"   # 自动路由：组件 root 查定义，壳工程 root 查全局调用方，合并输出
devflow-cg impact <symbol>     # 爆炸半径：多根时自动在壳工程 root 执行获取完整全局影响
devflow-cg status              # 新鲜度检查：比较 Podfile.lock / submodule HEAD 与索引修改时间
devflow-cg sync                # 只同步有文件变更的本地 path Pod
devflow-cg index               # 重建所有 root 全量索引，更新 lastRebuildAt
```

`analyze` / `design` / `code` / `fix` 四个命令中的 CodeGraph 调用均改为调用 `devflow-cg`，路由逻辑不再占用 LLM 推理资源。

#### `devflow continue` 新增索引新鲜度检查

会话恢复时自动检测：
- iOS 项目：Podfile.lock 比 `.codegraph/codegraph.db` 新 → 提示执行 `devflow-cg index`
- Android 项目：submodule HEAD 比 db 新 → 提示执行 `devflow-cg index`
- 本地 path Pod：源码文件比 db 新 → 提示执行 `devflow-cg sync`

发现过期时给出提示，不阻断流程，用户自行决定是否重建。

---

### `devflow quick` 三路径自动判断

原来 quick 命令分析完需求后统一走完整流程（design → plan → code），现根据 CodeGraph 影响符号数自动选择执行路径：

| 路径 | 触发条件 | 跳过步骤 | 典型场景 |
|------|---------|---------|---------|
| **极简** | 影响 ≤ 3 个符号 | 跳过 design + plan | 文案修改、配置项调整 |
| **快速** | 影响 4-10 个符号，无新增接口 | 跳过 design + plan | 小 UI 改动、接入已有接口 |
| **完整** | 影响 > 10 个符号，或需新增接口/模块 | 不跳过，转 devflow design | 架构变更、新功能 |

**极简路径**：分析完成后直接编码，全程 1 条命令。

**快速路径**：在 `requirement.md` 末尾追加内联方案节（改动文件清单 + 关键逻辑描述），用户确认一次后直接编码，不生成独立的 `spec/design.md` 和 `tasks.md`。

**完整路径**：需求分析已完成，直接进 `devflow design`，无需重新分析。

---

### 其他

- `workspace.tpl.json` 新增 `codegraph` 配置块（`strategy` / `roots` / `moduleRootMap` / `lastRebuildAt`）
- `references/codegraph-routing.md` 多根目录查询规则参考文档
- `docs/multi-repo-upgrade.md` 多仓库兼容升级详细说明

---

## v3.0.0 — 2026-08-05

初始发布。19 个命令覆盖需求分析到代码落地、Bug 修复、经验沉淀的全流程。详见 README。
