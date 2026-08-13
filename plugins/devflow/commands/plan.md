---
name: devflow-plan
description: DevFlow 任务拆解阶段。将技术设计拆解为原子任务，标注高风险操作，召回 Bug 经验，可同步到 Meegle 子任务。当用户说「任务拆解」「拆解任务」「devflow plan」或需要把设计方案转化为执行清单时触发。
---

# devflow plan — 任务拆解

**用途：** 将已冻结的技术设计拆解为标准格式的原子任务，标注高风险操作，从知识库召回 Bug 经验转化为验收约束，静默生成 `tasks.md` 无需人工确认，可选同步到 Meegle 子任务。

---

## 前置条件

- `spec/design.md` 存在（已冻结状态）。
- `spec/requirement.md` 存在。
- `meta.json` 状态为 `designing` / `estimating`（合法前驱）。

不满足时输出：
```
✗ 前置条件不满足：spec/design.md 不存在。
  请先执行 devflow design 完成技术设计。
```

---

## 执行步骤

### 1. 文档分析

阅读 `spec/requirement.md` 识别所有功能性需求，阅读 `spec/design.md` 识别所有核心模块和依赖关系。

### 2. Bug 经验召回

读取 `bug-experience-cards.csv`，匹配与当前需求涉及模块、接口、字段相关的经验卡：
- 命中经验卡的「禁止反模式」→ 转化为**实现约束**，写入对应任务描述
- 命中经验卡的「要求测试」→ 转化为**验收标准**，写入对应任务验收项
- 未命中或知识库不可读 → 注明「未召回 Bug 经验」，正常继续

**注入位置记录（供输出展示用）：** 每张命中的经验卡，记录其被注入的任务 ID 列表（如 T003、T007），格式：`{ cardId, severity, title, injectedTasks: [T001, ...] }`。用于步骤 5 输出时展示。

### 3. 拆解原子任务

将设计方案拆解为最小可执行的原子任务，按模块分组。

**高风险标注规则：**
- 涉及 MEDIUM 以上风险的任务 → 强制标注 `⚠️ [CodeGraph 前置检查]`
- 涉及 L0 模块的任务 → 标注 `🔒 [人工审查必须]`

**任务格式规范（每个任务必须包含所有字段）：**

```markdown
## 模块：{模块名称}

- [ ] **[T001] {任务名称}**
  - **Description**: {详细描述，说明做什么、在哪个文件、参考设计文档哪一节}
  - **Files**: `{涉及文件路径}`
  - **Technical Requirements**: {技术约束，如禁用 float 处理金额、必须加幂等键}
  - **Acceptance Criteria**:
    - [ ] {可检查的验收标准1}
    - [ ] {来自 Bug 经验卡的验收项，格式：`[KB-{id}]` 约束描述（如有）}
  - **Dependencies**: {前置任务 ID，如 T001；无则填 None}
  - **Risk**: {⚠️ [CodeGraph 前置检查] | 🔒 [人工审查必须] | 无}
```

### 4. 强约束验证

确认 `tasks.md` 包含必填章节：
- 执行清单（至少一个任务模块）
- Bug 经验编码禁令（来自经验卡的约束，无命中时写「无」）

  格式示例：
  ```markdown
  ## Bug 经验编码禁令
  - [KB-015] 禁止使用 Float/Double 处理金额，必须用 BigDecimal
  - [KB-009] Token 刷新必须加锁，防止并发多次刷新
  ```

### 5. 静默输出

**直接将结果写入 `tasks.md`，无需人工确认。**

### 6. Context Checkpoint

将任务概览写入 `progress.md`（任务数、高风险数、经验卡召回数）。

更新 `meta.json`：`status → planning`，`stages.planned = true`。

### 7. 可选：同步到 Meegle

若 `meta.json.linkedMeegleId` 存在，询问是否将任务列表同步为 Meegle 子任务：
```bash
meegle subtask update --work-item-id <id> --node-id <node_id>
```

---

## 输出

```
✅ 任务拆解完成。
  任务总数：{n} 个（分 {m} 个模块）
  高风险任务（需前置检查）：{n} 个
  L0 人工审查任务：{n} 个
  召回 Bug 经验卡：{n} 条
    · KB-{id}  [{severity}]  {title} → 注入 {T001, T002, ...}
    · KB-{id}  [{severity}]  {title} → 注入 {T003}
    （未命中时此列表不显示）
  Meegle 子任务：{已同步 n 个 | 未配置}

下一步：使用 `devflow code` 开始编码。
```
