---
name: devflow-change
description: DevFlow 需求变更处理。状态机强制回退，重新执行 CodeGraph 爆炸半径评估，可选更新 Meegle 工作项。当用户说「需求变更」「修改需求」「devflow change」或开发中途收到新的需求调整时触发。
---

# devflow change — 需求变更

**用途：** 处理需求变更，区分 Minor/Major 变更级别，状态机强制回退，重新评估影响面，可选更新 Meegle 工作项。

---

## 前置条件

- 活跃工作项存在（`workspace.json` 中 `currentWorkItem` 有效）。
- 变更描述已提供（通过 `$ARGUMENTS`）。

---

## 执行步骤

### 1. 变更分级

分析变更描述，确定变更级别：

| 级别 | 判断标准 | 处理 |
|------|---------|------|
| **Minor**（小改动） | UI 文案调整、单一字段变更、不影响架构 | 直接更新文档，状态轻量回退 |
| **Major**（架构级） | 影响核心业务流程、接口契约、模块拆分 | 完整重新评估，深度回退 |

向用户确认分级，不自行决定（Minor vs Major 的边界有主观判断空间）。

### 2. 记录变更

将变更描述和时间戳追加到 `spec/requirement.md` 末尾的「变更记录」章节：
```markdown
## 变更记录

| 时间 | 变更级别 | 变更内容 | 影响范围 |
|------|---------|---------|---------|
| {ISO时间戳} | Minor/Major | {描述} | {影响阶段} |
```

**必须**同时在 `progress.md` 中记录变更原因（变更历史可追溯）。

### 3. 状态机强制回退

| 当前状态 | Minor 回退到 | Major 回退到 |
|---------|------------|------------|
| `designing` 及之前 | `analyzing` | `analyzing` |
| `planning` / `estimating` | `designing` | `analyzing` |
| `coding` / `reviewing` | `designing` | `analyzing` |

更新 `meta.json` 状态及对应 `stages` 字段（重置被影响的阶段为 `false`）。

**已完成任务受变更影响时**：将受影响任务在 `tasks.md` 中标记为 `- [ ] ~~[已完成，需返工]~~`，不得静默保留旧状态。

### 4. CodeGraph 重新评估

对变更涉及的新增或修改符号执行：
```
codegraph_impact <涉及符号>
```

对比变更前后影响面差异，若影响面显著扩大，发出告警。

### 4.5 回归义务传播

CodeGraph 影响面确认后，扫描 `tasks.md` 中所有 `[x]`（已完成）任务：

1. 读取每个已完成任务的 `Files` 字段
2. 检查文件路径是否在 CodeGraph 爆炸半径（d=1 或 d=2）内
3. **命中的已完成任务**，区分两类处理：

   | 情况 | 标记方式 |
   |------|---------|
   | 实现需要修改（变更直接影响该任务的功能逻辑） | 任务状态改回 `- [ ]`（需返工） |
   | 实现不变但需重新验证（变更影响了依赖链） | 保持 `- [x]`，Verification 降级（locally_verified→code_done，runtime_verified→locally_verified），追加注释 `<!-- ⚠️ 回归义务：受变更 {日期} 影响，需重新验证 -->` |

4. 在 `open-issues.md` 追加一条 regression 类型条目：

   ```
   | {N+1} | 变更「{变更描述}」影响了已完成任务 {TID列表} 的文件范围，需回归验证 | regression | open | 变更记录 {日期} | {受影响任务列表} | 完成回归验证后关闭 | 对受影响任务重新执行本地验证 | {TID列表} |
   ```

`open-issues.md` 不存在时（旧工作项）跳过步骤 4，不报错。

根据回退状态，明确用户需要重新执行的步骤：
- 回退到 `analyzing` → 需重新执行 `devflow analyze → design → plan`
- 回退到 `designing` → 需重新执行 `devflow design → plan`

### 6. 可选：更新 Meegle

若 `meta.json.linkedMeegleId` 存在：
```bash
# 更新工作项描述（追加变更内容）
meegle workitem update \
  --work-item-id <id> \
  --fields '[{"field_key":"description","field_value":"<原描述>\n\n---\n**变更记录 {日期}**：{描述}"}]'

# 添加变更说明评论
meegle comment add \
  --work-item-id <id> \
  --content "🔄 需求变更（{Minor | Major}）\n\n变更内容：{描述}\n状态回退至：{状态}\n需重新执行：{steps}"
```

---

## 输出

```
### Change Processed
- **Type**: {Minor | Major}
- **状态回退至**: {analyzing | designing}
- **受影响任务**: {n} 个（已标记为需返工）
- **CodeGraph 影响面**: {未变化 | 扩大（需重新评估）}
- **变更记录**: 已写入 requirement.md 和 progress.md
- **Meegle 已更新**: {是 | 否}

需要重新执行：
→ devflow {next_step}
```
