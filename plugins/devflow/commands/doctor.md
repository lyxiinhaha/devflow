---
name: devflow-doctor
description: DevFlow 环境诊断。检查 DevFlow 运行所需的环境完整性和连通性，输出两级问题清单（🔴 必须修复 / 🟡 建议修复），每项附带修复命令。当用户说「检查环境」「环境诊断」「devflow doctor」或遇到 DevFlow 无法正常使用时触发。
---

# devflow doctor — 环境诊断

**用途：** 一键检查 DevFlow 运行环境，输出两级问题清单，支持 `--fix` 自动修复必须项。

---

## 调用方式

```
devflow doctor          # 全量检查（默认）
devflow doctor --fix    # 检查 + 对 🔴 必须修复项逐一确认后自动执行修复命令
devflow doctor --quick  # 仅检查 🔴 必须修复项，跳过 🟡 建议修复
```

---

## 检查项

### 🔴 必须修复（阻塞正常使用）

按顺序逐项检查，发现问题继续检查剩余项（不中断）：

| 检查项 | 检测方式 | 修复命令 |
|--------|---------|---------|
| `.devflow/workspace.json` 存在 | 检查文件是否存在 | `devflow init` |
| `workspace.json` 字段完整 | 检查 `techStack`、`codegraph` 节点存在 | `devflow init`（重新初始化） |
| CodeGraph 已安装 | 执行 `codegraph --version`，命令不存在则标记失败 | `npm install -g @colbymchenry/codegraph` |
| `bug-experience-cards.csv` 存在 | 检查 `.devflow/config/templates/knowledge/bug-experience-cards.csv` | `devflow init` |
| `knowledge-usage.jsonl` 存在 | 检查 `.devflow/config/templates/knowledge/knowledge-usage.jsonl` | `devflow init` |

### 🟡 建议修复（影响体验但不阻塞）

| 检查项 | 检测方式 | 修复建议 |
|--------|---------|---------|
| Hook 脚本存在且可执行 | 检查 `.devflow/hooks/devflow-audit.sh` 存在且有执行权限 | 重新执行 `devflow init` |
| Hook 已注册到 settings.json | 读取 `.claude/settings.json`，检查 `hooks.PostToolUse` 和 `hooks.PreToolUse` 字段 | 重新执行 `devflow init`（Claude Code 平台） |
| Meegle 已授权 | 执行 `meegle auth status`，命令不存在或未授权则标记警告 | `meegle auth login` |
| YApi 可达（若已配置） | 读取 `workspace.json.integrations.yapiHost`；若存在，执行 `curl -s --max-time 3 https://{yapiHost}/api/user/status`，失败则警告 | 检查 yapiHost 配置或网络连接 |
| CodeGraph 索引新鲜 | 若 `.codegraph/codegraph.db` 存在，比较其 mtime 与 `workspace.json.codegraph.roots` 下文件的最新 mtime；db 比源文件旧超过 24 小时则警告 | `codegraph index` |

---

## 执行逻辑

### 默认模式 / `--quick` 模式

逐项执行检查，收集所有结果，最终一次性输出报告。

`--quick` 模式跳过所有 🟡 项，只执行 🔴 项。

### 输出格式

```
DevFlow Doctor — 环境诊断
─────────────────────────────────────────────────
🔴 必须修复（{n} 项）
  ✗ {检查项名称}
    → 修复：{修复命令}

🟡 建议修复（{n} 项）
  ⚠ {检查项名称}
    → 修复：{修复建议}

✅ 通过（{n} 项）
  ✓ {检查项名称}（{可选补充信息，如：用户 yixin.liu / 最后更新 2小时前}）

总结：{n} 项必须修复，{n} 项建议修复。
运行 `devflow doctor --fix` 自动修复必须项。
```

全部通过时输出：
```
✅ DevFlow 环境一切正常，可以开始使用。
```

### `--fix` 模式

对所有 🔴 项展示将要执行的修复命令列表，等待用户确认后逐项执行：

```
即将自动修复 {n} 项：
  1. {修复命令 1}
  2. {修复命令 2}

继续？[y/N]
```

用户确认后逐项执行，每项输出执行结果（成功 ✅ / 失败 ✗ + 错误信息）。

---

## 前置条件

- 在项目根目录执行（需要能访问 `.devflow/`、`.claude/` 等目录）
- 无其他前置依赖，即使 DevFlow 未初始化也可运行（这是诊断命令的核心价值）
