# DevFlow：让 AI 真正参与研发全流程

> 技术分享 · 工程实践系列 · 2026-08-25

---

## 一句话是什么

DevFlow 是一套运行在 Claude Code / Cursor / Codex 上的 AI 工作流框架，用 **20 个命令** 覆盖从需求分析到经验沉淀的完整研发生命周期，深度集成 CodeGraph 代码知识图谱和团队经验知识库，让 AI 不只是写代码，而是真正参与每一个研发决策节点。

---

## 背景：AI 编码工具的局限

市面上的 AI 编码工具解决的是「如何写代码」，而真实的研发工作远不止于此：

- 需求来了，怎么分析、拆解、对齐设计稿和接口？
- 动手之前，怎么知道这个改动影响了哪些模块？
- 写完代码，怎么做 Review，怎么验证？
- 修了一个 bug，怎么保证下次不重蹈覆辙？
- 团队经历的踩坑，怎么让每一个人都能受益？

这些问题，靠「让 AI 帮我写代码」解决不了。DevFlow 尝试解决的是**整个研发流程的 AI 化**，而不只是编码环节。

---

## 完整工作流

8 个阶段，20 个命令，没有断点：

```
devflow start     →  需求创建与信息收集
devflow analyze   →  需求分析（含 Figma / 接口文档交叉核验）
devflow design    →  技术设计（CodeGraph 爆炸半径评估）
devflow plan      →  任务拆解（经验卡自动注入约束）
devflow code      →  编码（Worktree 隔离，项目规则始终生效）
devflow review    →  代码审查（退步检查，反模式扫描）
devflow fix       →  Bug 修复（90 分准入门禁，最小修复原则）
devflow retrospect →  强制复盘（经验卡自动入库，知识库持续生长）
```

每个命令都有明确的**前置条件、门禁检查和输出标准**，不允许静默跳过。

---

## 三个核心差异点

### 1. CodeGraph — AI 能看懂代码结构

DevFlow 深度集成 CodeGraph，让 AI 在每个关键决策点都能精确感知代码：

- **需求分析时**：自动反查涉及模块的现有接口，发现遗漏
- **技术设计时**：一次查询返回相关符号的逐行源码 + 调用路径，等效于已 Read 了那些文件
- **任务拆解时**：计算爆炸半径，CRITICAL（30+ 调用方）强制拦截，不让 AI 自作主张动高风险代码
- **编码时**：修改已有文件前强制读取原有逻辑，陈述「原有逻辑做了 X，本次只改 Y，不影响 Z」

**实际案例（hssa 项目）**：

```
案例 B：账户页条件单成交回报后只刷新数量接口（Issue #7068108607）

症状：收到成交回报后，条件单列表不刷新，需手动下拉。
直觉修法：在成交回报订阅里直接加列表刷新调用。

CodeGraph 追踪结果：
  StockDeliverSubscription → AccountCondOrderPresenter.observeStockDeliverRefresh()
      → if (moduleVisible) → RefreshCurrentList → loadData()
           ↑
           moduleVisible 始终为 false ← 这里断了

根因：RecentCondOrderViewModel.onModuleVisibleChanged() 是空方法，
      Fragment 调用了它但什么都没发生。

修复：一行代码
  fun onModuleVisibleChanged(visible: Boolean) {
      presenter.setModuleVisible(visible)
  }
```

直觉修法和真正根因的距离就是 CodeGraph 的价值所在。

---

### 2. 三层知识体系 — 经验不再停留在记忆里

传统团队的经验只有两个结局：要么在 Review 时口头提醒，要么彻底遗忘。DevFlow 把知识固化到研发流程里：

```
Layer 1  项目规则（project-rules.md）
         ↑ 始终生效，plan/code/review 自动注入
         ↑ 由 devflow knowledge distill 从经验卡提炼

Layer 2  经验卡（bug-experience-cards.csv）
         ↑ 模块匹配时召回，直接转化为任务约束 + 验收标准

Layer 3  Bug 修复清单（历史案例，按需查询）
```

**Layer 2 召回实例（hssa 项目 - 晒单授权弹窗需求）**：

`devflow plan` 阶段自动召回 9 张经验卡，每张直接注入任务约束：

| 禁令 | 来源卡 |
|------|--------|
| 禁止在 Fragment 直接调用 `SensorsTool`，必须通过 object 收口 | KB-030 |
| Click 埋点必须在 `setOnClickListener` 内第一行触发 | KB-033 |
| 弹窗必须继承 `DTCommDialogFragment`，禁用系统 `AlertDialog` | KB-026 |
| `show()` 必须使用安全重载，禁止 `super.show(manager, tag)` | KB-027 |
| 布局方向属性用 `start/end`，禁止 `left/right` | KB-021 |

这 9 条禁令是团队过去几个月踩坑后沉淀的，执行这个需求的工程师**不需要事先知道这些坑的存在**。

**Layer 1 蒸馏实例**：

6 张埋点经验卡（KB-030 到 KB-035）积累后，执行 `devflow knowledge distill tag=android-sensor`，AI 提炼出一条项目规则：

```markdown
## 埋点必须收口到模块级 object（来源：KB-030~KB-035，创建：2026-08-05）

所有埋点调用必须通过模块级 object 统一管理，禁止在业务文件中直接调用 SensorsTool。
Click 埋点在点击时立即触发，计时 Start/End 必须使用同一常量确保配对。

**禁止：**
- Fragment/ViewModel 中直接调用 SensorsTool.sensorsOnEventAttach()
- Click 埋点放在网络请求回调或 dismiss 之后
- TimerStart/TimerEnd 使用不同字符串字面量

**必须：**
- 每个模块新建独立的 Sensor object 文件
- Click 事件在 setOnClickListener 内第一行触发
- 计时事件用常量声明确保 Start/End 名称一致
```

规则写入后，每次 `devflow plan`/`code`/`review` 都会看到这条约束，无需召回匹配。

---

### 3. 状态机 + 门禁 — AI 不会越权决策

DevFlow 的每个阶段都有明确的门禁：

| 门禁 | 机制 |
|------|------|
| **爆炸半径门禁** | 0-2 LOW / 3-10 MEDIUM / 11-30 HIGH 暂停确认 / 30+ CRITICAL 强制拦截 |
| **分析质量门禁** | 信息完整性+根因定位+方案质量+影响范围+验证方案，≥ 90 分才进入修复 |
| **CRITICAL 审查门禁** | Review 发现安全漏洞、被删除安全兜底、影响面超预期，输出 BLOCKED 阻止合并 |
| **人工验证门禁** | 修复完成后不自动提交，展示 diff 等待确认，「验证通过」后才 commit |

这些门禁的本质是：**把有经验的工程师会做的判断，编码进流程里**，让 AI 不需要每次靠自身判断来决定该不该继续。

---

## 真实 ROI — hssa 项目数据

hssa 项目使用 DevFlow 至今已积累：

| 指标 | 数据 |
|------|------|
| 经验卡总量 | 48 张（KB-009 到 KB-048，模板 20 张 + 项目专属 28 张） |
| 覆盖领域 | Android Design Token（9 张）、埋点架构（6 张）、跨平台对齐（5 张）、金融计算（4 张）、合规门禁（2 张） |
| 单次最多召回 | 9 张（晒单授权弹窗需求） |
| 沉淀 CRITICAL 卡 | KB-027 Dialog 崩溃、KB-043 合规授权绕过 |

KB-043（合规授权门禁被绕过）是一个典型案例：`fm == null` 时降级直接执行受保护操作，这不是能靠直觉发现的问题，但沉淀成卡片后，每次涉及「弹窗 + 授权门禁」的需求都会自动出现这条约束。

---

## 快速开始

### 安装

```bash
# Claude Code
claude plugins install @devflow/devflow

# Cursor — 复制规则文件到项目根
cp devflow/adapters/cursor/.cursor/rules/devflow.mdc .cursor/rules/
```

### 初始化项目

```bash
devflow init
```

自动检测技术栈（Android/iOS/KMP/Vue/React/Spring Boot/Go/Node.js），配置 CodeGraph 和知识库，生成 `.devflow/` 目录结构。

### 检查环境

```bash
devflow doctor
```

### 开始第一个需求

```bash
devflow start
# 进入 Intake Mode，逐段输入需求内容
# 说「就这些了」触发最终需求分析
devflow design    # 技术设计
devflow plan      # 任务拆解（自动召回经验卡）
devflow code      # 编码
devflow review    # 代码审查
devflow retrospect # 复盘入库
```

### 不想全套流程？用 Lite 版

`docs/bug-fix-prompt-lite.md` 里有一份提示词，复制粘贴到任意 Claude 对话，不安装任何工具就能用结构化的 Bug 修复流程（含爆炸半径评估和 90 分准入门禁）。

---

## 常见问题

**Q：需要 CodeGraph 吗？**

CodeGraph 是推荐配置，DevFlow 有完整的降级路径（grep/find）。没有 CodeGraph 也能用，只是 AI 定位代码的效率会低一些。

**Q：知识库是每个项目独立的吗？**

是的。`.devflow/config/templates/knowledge/bug-experience-cards.csv` 存在项目目录里，纳入 git 版本管理，团队共享。DevFlow 包自带 20 张通用模板卡，项目在使用过程中不断追加自己的卡。

**Q：多平台（Android + iOS + KMP）支持吗？**

完整支持。`devflow design` 会按技术栈生成对应的平台专项设计文档（`design_android.md` / `design_ios.md` / `design_kmp.md`），`devflow plan` 和 `devflow code` 也针对各平台有专项逻辑。

**Q：已有项目能迁移进来吗？**

执行 `devflow init` 在现有项目根目录初始化即可，不会修改任何现有文件。知识库从空开始，随着每次 `devflow retrospect` 执行逐步积累。

---

## 总结

DevFlow 试图回答的核心问题是：**AI 如何成为一个有记忆的团队成员，而不只是一个代码生成器？**

- 有记忆 → 知识库三层体系，团队踩过的坑自动变成下次开发的约束
- 有判断 → CodeGraph 让 AI 看懂代码，爆炸半径门禁让 AI 知道什么时候该停
- 有流程 → 状态机驱动 8 阶段，每个节点有输入、门禁和输出标准
- 有闭环 → 强制复盘把每次开发的学习转化为系统性知识

好的工程工具不限制工程师的创造力，而是把工程师从重复性判断疲劳中解放出来。DevFlow 想做的就是这件事。

---

*DevFlow v3.8.0 | [项目地址](https://github.com/lyxiinhaha/devflow) | [完整命令文档](./plugins/devflow/commands/README.md)*
