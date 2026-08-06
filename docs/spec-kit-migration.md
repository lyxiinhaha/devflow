# DevFlow vs Spec-Kit 对比与迁移指南

> 面向已使用 Spec-Kit 的用户，说明两套工作流的异同，以及迁移时需要调整的习惯。

---

## 一句话定位差异

| | Spec-Kit | DevFlow |
|---|---|---|
| **定位** | 通用 Spec-Driven 框架，适配 30+ AI Agent | 面向移动端/KMP 项目的研发工作流，深度绑定华盛技术栈 |
| **安装方式** | `specify` CLI（Python/uv） | Claude Code 插件（`claude plugins install devflow`） |
| **核心理念** | 先写 Spec 再生成代码（Spec → Plan → Tasks → Implement） | 边分析边推进，深度集成 CodeGraph + Meegle + Figma + YApi |
| **扩展方式** | Extensions / Presets / Bundles | 团队 `ai-files/skills/`（`devflow sync` 分发） |

---

## 命令对照表

| Spec-Kit 命令 | DevFlow 命令 | 说明 |
|---|---|---|
| `specify init` | `devflow init` | 初始化工作区 |
| `/speckit.constitution` | — | DevFlow 无对应命令，安全分级（L0/L1/L2）覆盖部分能力 |
| `/speckit.specify` | `devflow start` + Intake Mode | spec-kit 是一次性写完，devflow 是逐段发送边录边析 |
| `/speckit.specify`（清晰小需求） | `devflow quick` | 直接把描述传入，一步完成分析 |
| `/speckit.clarify` | Intake Mode 内置 | devflow 在每段输入时即时追问，无需单独命令 |
| `/speckit.plan` | `devflow design` | 技术方案，devflow 额外生成对外走查文档 |
| `/speckit.tasks` | `devflow plan` | 任务拆解，devflow 支持标准化格式 + Bug 经验召回 |
| `/speckit.implement` | `devflow code` | 编码执行，devflow 加入 CodeGraph 复用探查 |
| `/speckit.converge` | — | DevFlow 无直接对应，`devflow review` 覆盖部分能力 |
| `/speckit.analyze` | 内置于 `devflow analyze` Finalize 阶段 | 一致性检查已内嵌 |
| `/speckit.checklist` | `devflow review` 的反模式扫描 | devflow 的知识库经验卡覆盖类似能力 |
| — | `devflow estimate` | **Spec-Kit 无对应**：工时估算 + Meegle 排期同步 |
| — | `devflow fix` | **Spec-Kit 无对应**：Meegle issue 批量修复完整流程 |
| — | `devflow refactor` | **Spec-Kit 无对应**：重构基线验证 |
| — | `devflow retrospect` | **Spec-Kit 无对应**：强制复盘 + 经验卡入库 |
| — | `devflow onboard` | **Spec-Kit 无对应**：模块架构导览 |
| — | `devflow knowledge` | **Spec-Kit 无对应**：团队 Bug 经验知识库 |
| `specify extension add` | `devflow sync` | 团队 AI 文件分发，机制不同 |
| `specx-sync-ai-files` / `specify` | `devflow sync` | 同步团队 skill |

---

## 工作目录结构对比

```
Spec-Kit                          DevFlow
─────────────────────────────     ─────────────────────────────
.specify/                         .devflow/
├── templates/                    ├── workspace.json        ← 当前工作项指针
├── extensions/                   ├── config/
└── presets/                      │   ├── devflow.json      ← 状态机配置
                                  │   ├── ai-policy.json    ← AI 安全策略
specs/                            │   └── templates/
├── spec.md           ←→          └── work-items/
├── plan.md                           └── {date}-{slug}/
└── tasks.md                              ├── meta.json     ← 状态机
                                          ├── context/
                                          │   └── sanitized.md ← PRD 内容
                                          ├── spec/
                                          │   ├── requirement.md ←→ spec.md
                                          │   ├── design.md      ←→ plan.md
                                          │   └── tech-design-doc.md（新增）
                                          ├── tasks.md           ←→ tasks.md
                                          └── progress.md        ← Checkpoint
```

---

## 主要流程差异

### 1. 需求输入方式

**Spec-Kit：** 一次性写完，`/speckit.specify` 接收完整描述，再用 `/speckit.clarify` 补充歧义。

**DevFlow：** Intake Mode，逐段发送，每段立即解析、即时追问：
```
[你发一段]  →  AI 立即提取功能点，发现歧义当场问
[你发 Figma 链接]  →  AI 立即读设计稿，与文字交叉核验
[你发 YApi 链接]  →  AI 立即读接口定义，核验字段
[就这些了]  →  触发 Finalize，生成完整需求文档
```

迁移习惯：**不需要一次写完所有内容**，可以分批发，AI 会帮你整理。

---

### 2. 技术方案（Plan → Design）

**Spec-Kit：** `/speckit.plan` 接收技术栈说明，输出 `plan.md`，无代码约束检查。

**DevFlow：** `devflow design` 额外做：
- CodeGraph 爆炸半径评估（影响 11+ 个调用方会暂停确认）
- Bug 经验转化为设计约束（如涉及金额字段自动加精度约束）
- 边设计边追问技术决策（不是最后一次性列问题）
- 额外生成 `spec/tech-design-doc.md`（含时序图、文件清单、测试验收清单，可直接走查）

迁移习惯：设计阶段**不需要你主动提供接口文档**，AI 会先通过 CodeGraph 查现有实现，再搜 YApi，找不到才问你。

---

### 3. 任务拆解（Tasks）

**Spec-Kit：** `/speckit.tasks` 输出任务列表，格式自由。

**DevFlow：** `devflow plan` 强制标准格式：
```markdown
- [ ] **[T001] 任务名**
  - Description: 做什么、在哪个文件
  - Files: com/xxx/XxxViewModel.kt
  - Technical Requirements: 禁止 float 处理金额
  - Acceptance Criteria:
    - [ ] 来自 Bug 经验卡的验收项
  - Dependencies: None
  - Risk: ⚠️ [CodeGraph 前置检查]
```

迁移习惯：无需手动写任务格式，AI 自动生成，**Bug 经验卡里的防坑项会自动转为验收标准**。

---

### 4. 编码执行（Implement → Code）

**Spec-Kit：** `/speckit.implement` 直接执行，无代码复用检查。

**DevFlow：** `devflow code` 每个任务编码前先 CodeGraph 探查现有实现：
- 找到现有实现 → 直接复用，不重复造轮子
- 找到部分匹配 → 改造复用
- 未找到 → 才新建

迁移习惯：**AI 不会重复造轮子**，会先查项目里有没有类似实现。

---

### 5. Bug 修复

**Spec-Kit：** 无内置 Bug 修复流程。

**DevFlow：** `devflow fix` 完整闭环：
```
devflow fix https://project.feishu.cn/...
```
- 自动读取 Meegle issue 详情
- 三阶段 CodeGraph 根因分析
- 90 分评分准入门禁（分数不够拒绝修复）
- 生成修复清单，人工验证后才提交
- 强制复盘 + 经验卡入库

---

### 6. 经验积累

**Spec-Kit：** 无内置经验积累机制，依赖 Extensions 扩展。

**DevFlow：** 内置知识库（`bug-experience-cards.csv`）：
- `devflow fix` / `review` / `refactor` 完成后自动触发复盘
- 每次复盘生成经验卡草稿，确认后入库
- 后续 `devflow plan` / `devflow code` 自动召回相关经验卡

---

### 7. 状态管理

**Spec-Kit：** 无显式状态机，通过文件是否存在判断阶段。

**DevFlow：** 显式状态机（`meta.json`），合法状态转换路径由 `devflow.json` 定义：
```
created → analyzing → designing → planning → coding → reviewing → done
```
跨阶段跳转会被阻断，防止跳过关键步骤。

---

## 核心能力对比

| 能力 | Spec-Kit | DevFlow |
|------|---------|---------|
| 通用 AI Agent 支持（30+） | ✅ | ❌（仅 Claude Code） |
| 自定义模板/格式（Presets） | ✅ 完整支持 | ❌（模板固定） |
| 社区 Extensions 生态 | ✅ 开放社区 | ❌（团队内部扩展） |
| 需求逐段录入（Intake Mode） | ❌ | ✅ |
| Figma 设计稿自动读取 | ❌ | ✅ Figma Desktop MCP |
| YApi 接口自动读取 | ❌ | ✅ WebFetch |
| CodeGraph 代码图谱分析 | 可选扩展 | ✅ 内置强依赖 |
| Meegle 项目管理联动 | ❌ | ✅ 全流程联动 |
| Bug 修复完整流程 | ❌ | ✅ 含评分门禁 |
| 工时估算 | ❌ | ✅ 三点置信区间 |
| 强制复盘 + 经验库 | ❌ | ✅ 自动触发 |
| 安全分级（L0/L1/L2） | ❌ | ✅ |
| 对外技术方案文档 | ❌ | ✅ 含时序图/文件清单 |

---

## 迁移检查清单

从 Spec-Kit 迁移到 DevFlow 时，以下习惯需要调整：

- [ ] **不再需要一次写完完整 Spec**：改用 `devflow start` 后逐段发送，或用 `devflow quick` 一步完成
- [ ] **不需要手动搜集接口文档**：`devflow analyze` 和 `devflow design` 会自动通过 CodeGraph + YApi 找
- [ ] **不需要手动写任务格式**：`devflow plan` 自动生成标准格式
- [ ] **编码前先等 CodeGraph 探查**：`devflow code` 会先查现有实现再动手
- [ ] **Bug 修复改用 `devflow fix`**：直接传 Meegle issue 链接，不手动分析
- [ ] **每次修复/重构后执行 `devflow retrospect`**：积累团队经验，后续自动复用
- [ ] **替换 `specify init` 为 `devflow init`**：首次配置 CodeGraph + Meegle + 安全分级

---

## 不适合迁移的场景

以下场景继续用 Spec-Kit 更合适：

- 需要支持多种 AI Agent（Copilot / Cursor / Codex 等）
- 需要高度自定义需求文档格式（Presets）
- 绿地（Greenfield）项目，没有现有代码库可查
- 团队不使用 Meegle 和 YApi
- 非 Claude Code 环境
