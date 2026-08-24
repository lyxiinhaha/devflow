# DevFlow 知识库：让团队经验自动进入开发流程

> 技术分享 | DevFlow 工程实践系列

---

## 一句话是什么

DevFlow 知识库不是一个文档库，而是一个**自动介入编码环节的 Bug 防护系统**。

你们团队踩过的每一个坑，在下一次相关开发开始之前，会自动转化成代码实现约束和验收标准，注入进任务清单里。

---

## 背景：知识沉淀的现实困境

几乎每个团队都有过这样的经历：

- 同一个 Bug 隔半年再次出现，而上次修复它的人已经不在团队了
- Review 会上有人提醒「这个模块之前出过类似问题，要小心」，但具体细节记不清了
- 写 Confluence 文档是奢望，能写一条 详细的bug 评论已经很不容易了
- 复盘会开了很多次，但复盘内容到下一次开发的时候已经没人记得

**这不是工程师的问题，而是知识存储位置的问题。**

经验放在人的记忆里，不可检索，不可传承，不能自动出现在需要它的地方。

DevFlow 知识库尝试解决的是：**把团队经验放到正确的位置——任务清单里，而不是记忆里**。

---

## 核心机制：三段闭环

```
[修复/开发完成]
      │
      ▼
  强制复盘  ←─── devflow retrospect
  生成经验卡
      │
      ▼  
 知识库存储  ←─── bug-experience-cards.csv
  (20 条→ 持续增长)
      │
      ▼
  任务拆解时  ←─── devflow plan
  自动召回
  转化为约束+验收
      │
      ▼
  追踪使用效果  ←─── knowledge-usage.jsonl（本周新增）
  自动推断 outcome
      │
      ▼
  质量面板评估  ←─── devflow knowledge check（本周升级）
  清理低效卡
      │
      └──────────────→（回到复盘，形成闭环）
```

这三段对应三个核心命令：`retrospect`（沉淀）→ `plan`（召回）→ `knowledge check`（评估）。

---

## 第一段：沉淀 — devflow retrospect

### 触发机制

复盘不是可选项。以下情况自动触发：

- `devflow fix` 完成且验证通过
- `devflow review` 发现需要沉淀的问题
- `devflow refactor` 完成且基线一致性通过
- CRITICAL 级别 Bug 修复完成

不等人想起来，流程结束即触发。

### 生成的经验卡结构

每张经验卡记录以下字段：


| 字段               | 说明                             | 约束     |
| ---------------- | ------------------------------ | ------ |
| `root_cause`     | 根本原因                           | 不得为空   |
| `anti_patterns`  | 导致问题的错误代码模式                    | 不得为空   |
| `required_tests` | 必须补充的测试场景                      | 不得为空   |
| `severity`       | CRITICAL / HIGH / MEDIUM / LOW | 必填     |
| `tags`           | 逗号分隔的关键词                       | 至少 1 个 |


`anti_patterns` 和 `required_tests` 是最重要的两个字段——它们是可以直接注入任务清单的内容。

### 当前知识库快照（20 条，持续增长）


| Severity | 数量  | 代表条目                                                                                   |
| -------- | --- | -------------------------------------------------------------------------------------- |
| CRITICAL | 3   | KB-005 SQL 注入、KB-015 金额浮点精度、KB-019 XSS                                                 |
| HIGH     | 9   | KB-001 Promise 并发竞态、KB-003 Redux state mutation、KB-009 Token 刷新、KB-013 WebSocket 重连... |
| MEDIUM   | 8   | KB-002 接口 null 防御、KB-004 useEffect 内存泄漏、KB-007 时区不一致...                                |


3 条 CRITICAL 覆盖安全和金融核心场景，HIGH/MEDIUM 覆盖最常见的前端架构和异步问题。

### 三维去重检测（防止知识库膨胀）

写入前自动检测与已有卡的相似度：


| 维度                           | 命中阈值     |
| ---------------------------- | -------- |
| 标题关键词重叠                      | &gt; 60% |
| `root_cause` + `module` 同时匹配 | 两字段都命中   |
| `anti_patterns` 关键词重叠        | &gt; 50% |


命中时提供三个选项：合并到已有卡 / 新增为独立卡 / 放弃当前草稿。这保证了知识库不会出现大量重复但略有差异的卡片。

---

## 第二段：召回 — devflow plan

### 工作方式

在 `devflow plan`（任务拆解）阶段，系统读取 `bug-experience-cards.csv`，将当前需求涉及的模块与知识库进行匹配：

```
命中经验卡的「anti_patterns（禁止反模式）」
    → 转化为实现约束，写入对应任务描述

命中经验卡的「required_tests（要求测试）」
    → 转化为验收标准，写入对应任务验收项
```

**这意味着：你踩过的坑，在下一个开发者写第一行代码之前就已经变成了任务要求。**

### 输出示例

如果当前需求涉及支付模块，plan 阶段会自动输出：

```
── 召回 Bug 经验 ──────────────────────────────
[CRITICAL] KB-015 浮点数精度丢失（注入 T003, T007）
  实现约束：禁止使用 Float/Double 处理货币计算，必须使用 Decimal.js
  验收标准：金额边界值计算测试；与后端计算结果对比

[MEDIUM] KB-016 跨域请求未携带 Cookie（注入 T005）
  实现约束：fetch 请求必须设置 credentials: include
  验收标准：跨域认证接口测试；Cookie 携带验证
──────────────────────────────────────────────
```

开发者无需记忆历史教训，任务清单直接告诉他应该注意什么。

### 使用日志写入（本周新增）

每次经验卡被召回，系统向 `knowledge-usage.jsonl` 写入一条记录：

```json
{
  "ts": "2026-08-20T09:15:00Z",
  "card_id": "KB-015",
  "work_item": "20260820-PaymentRefactor",
  "recalled_by": "plan",
  "outcome": "unknown",
  "outcome_ts": null,
  "outcome_note": ""
}
```

这是知识库从「写入即遗忘」升级为「知道自己有没有被用上」的起点。

---

## 第三段：评估 — devflow knowledge check（本周核心升级）

### 召回效果自动推断（retrospect 步骤 0）

`devflow retrospect` 执行时，系统读取本次工作项的召回记录，从修改文件列表自动推断每张卡的实际效果：


| outcome      | 判断条件                                                |
| ------------ | --------------------------------------------------- |
| `applied`    | 卡片 `module` 与修改文件模块重叠，且 `required_tests` 出现在新增测试文件中 |
| `irrelevant` | 卡片 `module` 与本次所有修改文件无任何模块交集                        |
| `partial`    | `module` 有交集，但 `required_tests` 未在测试文件中找到对应覆盖       |
| `unknown`    | 无法从代码变更中判断                                          |


整个推断过程完全静默，不打扰用户。

### 质量信号面板

`devflow knowledge check` 现在输出两层信息：

**字段健康检查（原有）**

```
Knowledge Base Health Check
- Total Cards: 20
- Healthy Cards: 20
- Severity Distribution: CRITICAL: 3, HIGH: 9, MEDIUM: 8
```

**质量信号面板（本周新增）**

基于 `knowledge-usage.jsonl` 的实际使用数据：

```
── 高价值卡（召回≥3次 且 有效率≥60%）──────────────
  KB-001  Promise 并发竞态    召回 5次  有效 80%  最近: 12天前
  KB-015  金额浮点精度        召回 4次  有效 100% 最近: 3天前

── 待观察卡（召回≥1次 但 有效率<30%）────────────────
  KB-007  时区不一致          召回 2次  有效 0%   → 建议复查内容

── 沉睡卡（从未召回 或 90天无召回）──────────────────
  KB-020  动态导入初始化失败  从未召回            → 确认是否仍适用

整体：23次历史召回 · 整体有效率 72%
```

**有效率** = `applied` 次数 ÷（`applied` + `irrelevant`）次数。

一张被频繁召回且有效率高的卡是知识库的核心资产；一张从未召回的卡可能已经过时。

---

## 本周新增：知识库维护命令

### prune — 清理低效卡

```bash
devflow knowledge prune
```

自动识别三类候选清理卡：


| 类型      | 条件                          |
| ------- | --------------------------- |
| A「低效卡」  | 召回 ≥ 2 次 且 `applied` 率 = 0% |
| B「沉睡卡」  | 90 天内零召回                    |
| C「未验证卡」 | 创建超 60 天且从未被召回              |


逐张展示，等待用户决策：删除 / 保留 / 更新内容后保留 / 归档。**不自动删除任何卡**。

### dedupe — 去重合并

```bash
devflow knowledge dedupe
```

三维扫描检测候选重复组，AI 起草合并版本，用户确认后合并。合并时历史使用记录统一到存留卡 ID 上，数据不丢失。

---

## 对比：有知识库和没有知识库的开发流程


| 场景            | 没有知识库         | 有知识库                 |
| ------------- | ------------- | -------------------- |
| 同类 Bug 出现     | 靠有经验的人口头提醒    | plan 阶段自动出现在任务约束里    |
| 代码 Review     | 「这里要小心，之前踩过坑」 | 任务清单里已有明确的验收标准       |
| 新人 onboarding | 靠 mentor 传授经验 | 知识库召回覆盖所有模块，不依赖特定人   |
| Bug 复盘        | 会上讨论，基本不落地    | 强制生成经验卡，三维去重后入库      |
| 知识库质量         | 不知道哪些内容有用     | 质量面板量化每张卡的召回次数和有效率   |
| 过时内容清理        | 没有机制，靠人工扫描    | prune 命令基于使用数据自动识别候选 |


---

## 如何开始

### 方式一：安装 DevFlow（推荐）

```bash
# 在项目根目录执行
devflow init
```

初始化完成后，知识库和所有命令即可使用。完整流程是：

```
devflow start → devflow analyze → devflow design
    → devflow plan  ←── 这里自动召回知识库
    → devflow code
    → devflow review
    → devflow retrospect  ←── 这里自动沉淀到知识库
```

### 方式二：只用 Lite 版 Bug 修复（无需安装）

如果暂时不想引入完整工具链，可以直接使用 Lite 版提示词（见 `docs/bug-fix-prompt-lite.md`），粘贴到任意 Claude 对话即可获得结构化的 Bug 修复流程（含爆炸半径评估和 90 分准入门禁），只是没有知识库的自动召回能力。

### 方式三：手动查询知识库

知识库文件是标准 CSV，可以直接打开或用任意工具查询：

```bash
devflow knowledge query security       # 按 tag 查询
devflow knowledge query module=payment # 按模块查询
devflow knowledge check                # 质量健康检查
```

---

## 真实项目案例：hssa

以下案例来自 hssa Android 项目，这个项目使用 DevFlow 已积累了 **28 张项目专属经验卡**（KB-021 到 KB-048），覆盖 Android Design Token 规范、埋点架构、跨平台对齐和金融计算等核心模块。

---

### 案例一：一次功能开发召回 9 张卡 — 晒单授权弹窗

**背景**：新增一个合规需求——在持股晒单前弹出授权弹窗。功能本身不复杂，但涉及弹窗组件、埋点、多语言适配、按钮防重复提交等多个知识点。

**devflow plan 阶段**，系统自动召回了 9 张经验卡，每张卡直接注入对应任务的实现约束和验收标准：

```
召回 Bug 经验卡：9 条
  KB-010 / KB-021 / KB-022 / KB-023 / KB-026 / KB-027 / KB-030 / KB-031 / KB-032 / KB-033
```

任务清单底部自动生成了一张「禁令表」：


| 禁令                                                         | 来源卡    | 违反后果                                                |
| ---------------------------------------------------------- | ------ | --------------------------------------------------- |
| 禁止在 Fragment/ViewModel 直接调用 `SensorsTool`，必须通过 `object` 收口 | KB-030 | 埋点分散无法统一审计                                          |
| Click 埋点必须在 `setOnClickListener` 内第一行触发，不能放在回调内            | KB-033 | 接口失败时漏报点击事件                                         |
| Got it 点击后立即 `isEnabled = false`                           | KB-010 | 快速双击导致重复网络请求                                        |
| 弹窗必须继承 `DTCommDialogFragment`，禁用系统 `AlertDialog`           | KB-026 | 夜间主题不适配                                             |
| `show()` 必须使用安全重载，禁止 `super.show(manager, tag)`            | KB-027 | `onSaveInstanceState` 后抛 `IllegalStateException` 崩溃 |
| 布局控件必须用 DT 替代原生 `TextView`/`ImageView`                     | KB-023 | 夜间模式颜色不自动适配                                         |
| 布局方向属性用 `start/end`，禁止 `left/right`                        | KB-021 | AR 语言 RTL 下布局错乱                                     |
| 禁止硬编码色值 `#RRGGBB`                                          | KB-022 | 夜间模式颜色显示错误                                          |
| String Key 必须同时在 `values/` 和 `values-ar/` 中定义              | KB-021 | AR 用户看不到文案                                          |


**这 9 条禁令不是某个工程师从记忆里翻出来的**，它们是团队在过去几个月踩坑后沉淀的结果，由 plan 阶段自动匹配后注入的。做这个功能的工程师只需要对照任务清单执行，不需要事先知道这些坑的存在。

---

### 案例二：CRITICAL 合规门禁被绕过——沉淀为 KB-043

**发现过程**：晒单授权弹窗开发中，在 `PositionListAdapter` 里通过 `(it.context as? FragmentActivity)?.supportFragmentManager` 获取 FM 来展示授权弹窗。当时有人提出：如果 `fm == null` 怎么办？

初版写法是：

```kotlin
val fm = (it.context as? FragmentActivity)?.supportFragmentManager
if (fm != null) {
    ShareOrderAuthDialog.show(fm, ...)
} else {
    navigateToShare(...)  // ← 降级直接执行，绕过了合规授权
}
```

这是一个 CRITICAL 级别的问题：在无法展示授权弹窗的极端情况下，原本受合规保护的操作被直接执行了。

**复盘后写入知识库（KB-043）：**

```
issue_type: compliance_bypass
module: android-compliance
title: 合规授权门禁在降级场景中被绕过
root_cause: fm==null 等极端情况下为保证用户体验直接执行授权后才能执行的操作
anti_patterns: fm==null 时 else navigateToShare()（直接绕过弹窗继续）
required_tests: fm 为 null 时操作被静默丢弃不执行受保护的功能
severity: CRITICAL
```

**这张卡的价值**：下一个涉及「弹窗 + 授权门禁」场景的需求，plan 阶段会自动召回这张卡，实现约束直接出现在任务描述里——不需要有人记得这次复盘。

---

### 案例三：格式化逻辑改写丢失正号 — KB-046 + KB-047

**背景**：基金展示字段调整，需要修改涨跌幅的格式化方式，将 `format2Amount(true)` 改为直接字符串拼接。

**问题**：改写后，正数涨跌幅从 `+5.23%` 变成了 `5.23%`，少了 `+` 号。

**根因**：`format2Amount(isNeedAdd = true)` 内部除了控制小数位，还调用了 `addPrefix()` 给正数加 `+` 号。改写时只看到了「两位小数」这个功能，没有意识到 `isNeedAdd=true` 这个参数还附带了一个副作用。

这次复盘沉淀了两张卡：

**KB-046**（金融专项）：

```
title: 涨跌幅/涨跌额字段裸拼字符串丢失正数加号
anti_patterns: 直接用 "$value%" 拼接涨跌幅字段，不调用 addPrefix()
required_tests: 正数显示 +5.23%；负数 -5.23%；零值无符号
severity: HIGH
```

**KB-047**（过程专项）：

```
title: 改动原代码时未理解原有逻辑导致功能丢失
anti_patterns: 看到「这段代码可以简化」就直接替换，不先读完原代码的完整行为
required_tests: 改前列出原代码完整行为清单；改后逐条验证原功能未丢失
severity: HIGH
```

KB-047 这张卡的价值不只是针对这个具体问题——它描述的是一类普遍的编码失误模式，适用于任何改写场景。

---

### 知识库规模对比


|            | 模板初始值   | hssa 项目当前                            |
| ---------- | ------- | ------------------------------------ |
| 总卡数        | 20 张    | 28 张（+8 张项目专属）                       |
| 覆盖模块       | 通用前端/后端 | Android Design Token、埋点架构、双平台对齐、金融计算 |
| CRITICAL 卡 | 3 张     | 新增 KB-027（Dialog 崩溃）、KB-043（合规绕过）    |


hssa 项目的 8 张增量卡全部来自真实的 Bug 复盘和 Review 发现，这是知识库的核心价值：**随着项目和团队的成长，知识库也在生长**。

---

## 常见问题

**Q：经验卡写错了怎么办？**

`devflow knowledge prune` 可以选择「更新内容后保留」，进入编辑流程，历史召回记录不丢失。

**Q：多个团队共用一个知识库行不行？**

完全支持。`bug-experience-cards.csv` 是纯文本文件，可以纳入 git 版本管理，团队合并通过普通 merge 解决，使用 `devflow knowledge dedupe` 定期清理重复。

**Q：知识库内容会不会泄露给其他项目？**

知识库文件位于项目目录 `.devflow/config/templates/knowledge/` 下，只在本项目中生效，不会跨项目共享。

**Q：如果 devflow plan 召回了一张不相关的卡怎么办？**

`knowledge-usage.jsonl` 会记录此次召回。在 `devflow retrospect` 时系统会推断 outcome 为 `irrelevant`，该卡的有效率会下降，一段时间后会出现在 `prune` 的待观察列表里。

---

## 总结

知识库本周的升级（usage 追踪 + 自动 outcome 推断 + 质量面板 + prune/dedupe）解决的核心问题是：

**知识库从「存了就不管了」变成了「可以量化哪些知识真正被用上了」。**

高有效率的卡是团队真正的防护资产；沉睡卡是需要审视的潜在废料；`prune` 和 `dedupe` 让知识库可以保持精简和高质量。

一个健康的知识库不在于卡片多，而在于每张卡在被调用时都能产生实际约束。

---

*DevFlow v3.6.0 | 知识自进化特性*  
*项目地址：[plugins/devflow/commands/](../plugins/devflow/commands/)*  
*知识库路径：[.devflow/config/templates/knowledge/bug-experience-cards.csv](../.devflow/config/templates/knowledge/bug-experience-cards.csv)*