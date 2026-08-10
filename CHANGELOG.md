# Changelog

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
