# DevFlow 多仓库兼容升级说明

**版本：** v3.1.0  
**涉及提交：** `ec7dcc9` → `7506606`

---

## 背景

Android / KMP 项目通过 git submodules 引用多个子仓库，iOS 项目通过 CocoaPods 引入 400+ 个 Pod 组件，部分 Pod 通过 `:path =>` 本地路径联调。原有 DevFlow 对这些场景缺乏感知，CodeGraph 查询无法正确覆盖所有代码，也不处理组件更新后的索引失效问题。

---

## 一、变更内容

### 1. `devflow init` — 项目类型自动检测

新增**项目类型检测**（步骤 2），根据检测结果生成对应的 CodeGraph 索引策略，写入 `workspace.json`：

| 项目类型 | 检测特征 | 索引策略 |
|---------|---------|---------|
| Android / KMP 壳工程 + submodules | `build.gradle` + `.gitmodules` 或 `submodules/` 目录 | **单根**：壳工程根目录一次 init，submodules 统一覆盖 |
| iOS CocoaPods | `Podfile` 存在 | **多根**：壳工程 + 每个本地 path Pod 各自 init |
| 完全独立多仓库 | 用户手动声明 | **多根**：逐一 init，用户提供各仓库路径 |
| 单仓库 | 其他 | **单根**：根目录一次 init |

**iOS CocoaPods 本地 Pod 探测：**
```bash
grep -E "pod.*:path\s*=>" Podfile
```
发现本地 path Pod 后，询问用户是否为每个 Pod 单独初始化索引。

**初始化结果写入 `workspace.json`：**
```json
{
  "codegraph": {
    "strategy": "single-root | multi-root",
    "roots": [
      { "path": ".", "covers": "壳工程源码 + Pods/ 源码", "rebuildOn": ["pod install", "pod update"] },
      { "path": "../HSAccountKit", "covers": "本地联调 Pod" }
    ],
    "moduleRootMap": {
      "HSAccountKit": "../HSAccountKit"
    },
    "lastRebuildAt": null
  }
}
```

**CLAUDE.md 自动注入多根查询规则**（新会话自动继承，无需手动配置）：
```markdown
## CodeGraph 多根目录查询规则
- 壳工程：{path}（覆盖：壳工程源码 + Pods/ 源码）
- 本地 Pod HSAccountKit：{path}
查询流程：
1. 查组件内部调用链 → cd 到组件目录
2. 查全局影响 → 在壳工程根目录
```

---

### 2. `devflow-cg` 脚本 — 多根路由移出 LLM

新增 `skills/devflow-cg/devflow-cg.sh`，替代命令文件中原有的路由推理描述。

**命令：**

| 命令 | 作用 |
|------|------|
| `devflow-cg explore "<query>"` | 符号/模块探查，自动按 `moduleRootMap` 路由，多根时执行两次并合并输出 |
| `devflow-cg impact <symbol>` | 爆炸半径分析，多根时自动在壳工程 root 执行（获取完整全局调用方） |
| `devflow-cg status` | 索引新鲜度检查（比较 Podfile.lock / submodule HEAD / .codegraph/codegraph.db 的修改时间） |
| `devflow-cg sync` | 只同步有文件变更的本地 path Pod，跳过无变更的 |
| `devflow-cg index` | 重建所有 root 全量索引，更新 `workspace.json` 的 `lastRebuildAt` |

**路由逻辑（bash，不经过 LLM）：**
- 读取 `workspace.json.codegraph.strategy`
- `single-root` → 直接在当前目录执行，无额外操作
- `multi-root` → 按 `moduleRootMap` 找对应组件 root，执行一次；再在壳工程 root 执行一次；合并输出

**新鲜度检查逻辑（bash，不经过 LLM）：**
```bash
# iOS：Podfile.lock 比 .codegraph/codegraph.db 新 → 提示重建
# Android：submodule HEAD 比 db 新 → 提示重建
# 本地 Pod：源码文件 mtime 比 db 新 → 提示 sync
```

---

### 3. 下游命令简化

`analyze` / `design` / `code` / `fix` 中原有的路由推理描述文字（每个文件约 150 token）统一替换为一行脚本调用：

```bash
# 之前（文字描述，进 context）
# 读取 workspace.json.codegraph，确定查询策略：
# - 单根项目：直接在当前目录执行 codegraph_explore
# - 多根项目：1. 先检查索引新鲜度 2. 查符号定义 → cd 到组件 root ...

# 之后（一行调用）
devflow-cg explore "<query>"
```

**`devflow continue` 新增索引新鲜度检查：**  
恢复会话时自动执行 `devflow-cg status`，发现过期索引时给出提示（不阻断流程）：
```
⚠️ 检测到 pod update 后 CodeGraph 索引未重建，建议执行：devflow-cg index
```

---

## 二、Token 实际影响

DevFlow 的 Token 消耗分两类，需分开讨论：

### 类型 A：命令文件加载到 context 的文字

每次会话加载 skill 文件时，文件里的所有文字都变成 Token 进入 context。

| | 优化前 | 优化后 | 节省 |
|---|---|---|---|
| analyze.md 路由描述 | ~150 token | ~10 token（一行命令） | ~140 token |
| design.md 路由描述 | ~150 token | ~10 token | ~140 token |
| code.md 路由描述 | ~200 token | ~15 token | ~185 token |
| fix.md 路由描述 | ~150 token | ~10 token | ~140 token |
| **合计（每次会话）** | **~650 token** | **~45 token** | **~605 token** |

### 类型 B：工具调用（Tool Call）

CodeGraph 工具调用（`codegraph_explore` / `codegraph_impact`）本身**不耗 Token**，调用是免费的。耗 Token 的是调用返回的结果进入 context，这部分不受本次优化影响。

### 实际节省

每次会话节省约 **600 token**，约占完整需求流程总 Token（~30,000-50,000 token）的 **1-2%**。

节省量级不大，但消除了一处「AI 推理无用路由逻辑」的浪费——这些路由判断用 bash 一秒内能算清楚，没有理由占用 LLM 的推理资源。

---

## 三、覆盖矩阵

| 场景 | 优化前 | 优化后 |
|------|--------|--------|
| 单仓库项目 | ✅ 正常 | ✅ 正常（strategy=single-root，无额外开销） |
| Android + submodules | ⚠️ 能查，但 submodule 更新后索引静默过期 | ✅ init 单根覆盖，continue 检测更新提醒重建 |
| iOS CocoaPods（pod 全在 Pods/） | ⚠️ 能查，但 pod update 后索引静默过期 | ✅ init 记录 rebuildOn，continue 检测 Podfile.lock 提醒重建 |
| iOS + 本地 path Pod（`:path =>`） | ❌ 完全看不到本地 Pod 代码 | ✅ init 探测 path Pod，单独 init，devflow-cg 自动路由 |
| 完全独立多仓库 | ❌ 只能查当前目录 | ✅ 用户声明后多根 init，devflow-cg 自动合并结果 |

---

## 四、使用变化（对现有用户）

**无破坏性变更。** 所有改动向后兼容：
- 已初始化的项目：`workspace.json` 无 `codegraph` 字段时，脚本回退到单根模式
- 新项目：`devflow init` 时自动检测并配置
- 需要补配现有项目：重新执行 `devflow init`（会追加配置，不覆盖现有工作项）

**新增可用命令：**
```bash
devflow-cg status    # 随时检查索引是否过期
devflow-cg index     # pod update / submodule update 后重建
devflow-cg sync      # 本地 Pod 改动后同步
```
