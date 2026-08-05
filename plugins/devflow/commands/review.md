---
name: devflow-review
description: DevFlow 代码审查阶段。验证 CodeGraph 影响面一致性，扫描反模式，可更新 Meegle 工作项状态。当用户说「代码审查」「review」「devflow review」或编码完成后需要审查代码质量时触发。
---

# devflow review — 代码审查

**用途：** 代码审查阶段，验证 CodeGraph 影响面一致性，按四维度（质量/安全/性能/反模式）审查，发现 CRITICAL 问题时阻断合并，可选更新 Meegle 状态。

---

## 前置条件

- `tasks.md` 中的任务应全部完成 `- [x]`（或用户明确说明只审查部分）。
- 代码可编译，基本测试通过。
- `meta.json` 状态为 `coding`（合法前驱）。

---

## 执行步骤

### 1. 影响面一致性验证

对本次修改涉及的所有符号执行：
```
codegraph_impact <符号>
```

将实际影响面与 `spec/design.md` 中「CodeGraph 爆炸半径评估」章节对比：
- 影响面收缩 → 正常，记录
- 影响面扩大 → **发出警告**，要求开发者解释并确认，写入 `review.md`
- CodeGraph 不可用 → 降级为手动代码搜索，注明「CodeGraph 不可用，手动审查」

### 2. 四维度代码审查

#### 代码质量
- 可读性与可维护性
- 命名规范，是否符合项目 style guide
- 复杂函数是否有必要注释

#### 安全性
- SQL / 命令注入风险
- 认证绕过、越权访问
- 敏感数据暴露（密钥硬编码、日志泄露）

#### 性能
- N+1 查询
- 内存泄漏（未清理的监听器、定时器）
- 低效循环（嵌套遍历大集合）

#### 反模式扫描
读取 `bug-experience-cards.csv`，扫描本次提交的代码是否包含已知高风险反模式，命中时写入审查报告。

### 3. CRITICAL 阻断门禁

发现以下任一问题时，输出 `BLOCKED` 状态，**必须阻止代码合并**：
- 安全漏洞（注入、越权、敏感数据暴露）
- 严重性能问题（可能导致服务不可用）
- 影响面超出设计预期且未确认

### 4. 生成审查报告

将审查结果写入 `review.md`。

更新 `meta.json`：`status → reviewing`，`stages.reviewed = true`。

### 5. 触发强制复盘

若审查中发现需要沉淀的通用问题，自动生成经验卡草稿，提示执行 `devflow retrospect` 入库。

### 6. 可选：更新 Meegle 状态

若 `meta.json.linkedMeegleId` 存在且审查通过：
```bash
meegle workflow list-state-transitions --work-item-id <id>
meegle workflow transition-state --work-item-id <id> --transition-id <id>

meegle comment add --work-item-id <id> \
  --content "✅ 代码审查通过\n\n**影响面**：{一致 | 扩大已确认}\n**Critical**：0\n**反模式**：{无 | n 处已修复}"
```

---

## 输出

```
### Code Review Report
- **Status**: [APPROVED | CHANGES REQUESTED | BLOCKED]
- **Critical Issues**: {n}（BLOCKED 时必须列出）
- **Minor Issues**: {n}
  - `{file}:{line}`: {问题描述}
- **影响面验证**: {一致 | 扩大（需确认）}
- **反模式命中**: {无 | n 处（已列入 review.md）}

Meegle 状态：{已流转至「{状态}」 | 未配置}

下一步：使用 `devflow retrospect` 沉淀本次开发经验。
```
