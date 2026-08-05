# DevFlow 需求开发工作流

**DevFlow v3** 是从需求到交付的全流程 AI 辅助研发工作流，深度集成 **CodeGraph 知识图谱** 与 **Meegle 项目管理**，内置状态机、安全分级、强制复盘和 Context Checkpoint。

---

## 快速开始

### 第一步：安装插件

```bash
# 在 Claude Code 中通过 marketplace 安装
claude plugins install devflow
```

### 第二步：初始化项目（每个项目只需一次）

```
devflow init
```

AI 将自动：
1. 检查并配置 CodeGraph（索引建立）
2. 检查并授权 Meegle（若已安装则验证授权，否则引导安装）
3. 建立 `.devflow/` 目录结构
4. 确认安全分级（L0/L1/L2）
5. 配置 Meegle 项目空间（可选）

### 第三步：开始开发

```
# 新功能需求
devflow start 用户头像上传，支持裁剪和预览

# 修复 Bug（可直接传 Meegle 工作项 ID）
devflow fix 12345678
devflow fix 登录后页面白屏，复现步骤：...

# 重构
devflow refactor UserService 模块

# 了解代码库
devflow onboard payment 模块
```

---

## 完整工作流

```
主线（Feature/Tech）：
start → analyze → design → estimate → plan → code → review → retrospect

Bug 修复：
fix → [自动触发] retrospect

重构：
refactor → review → retrospect
```

---

## 17 个命令说明

| 命令 | 触发语 | 核心能力 |
|------|--------|---------|
| `devflow init` | 初始化 DevFlow | 配置 CodeGraph + Meegle，建立工作区 |
| `devflow start` | 开始新需求 | 创建工作项，初始化状态机，可同步 Meegle |
| `devflow analyze` | 需求分析 | CodeGraph 代码核验 + 强约束模板 + Checkpoint |
| `devflow design` | 技术设计 | CodeGraph 爆炸半径评估，HIGH/CRITICAL 阻断 |
| `devflow estimate` | 工作量估算 | 基于影响面科学估算，可更新 Meegle 排期 |
| `devflow plan` | 任务拆解 | 原子任务 + Bug 经验召回 + Meegle 子任务同步 |
| `devflow code` | 开始编码 | 主动预警 + 前置检查门禁 + L0 安全限制 |
| `devflow fix` | 修复 Bug | 三次 CodeGraph 调用 + Meegle 状态流转 |
| `devflow refactor` | 代码重构 | 基线快照 + 重构后一致性断言 |
| `devflow review` | 代码审查 | 影响面验证 + 反模式扫描 + Meegle 流转 |
| `devflow retrospect` | 复盘 | 经验卡自动生成 + 知识库入库 + Meegle 关闭 |
| `devflow onboard` | 了解 xxx 模块 | CodeGraph 架构导览 + Meegle 近期工作项 |
| `devflow continue` | 恢复进度 | 读取 Checkpoint，展示 Meegle 最新状态 |
| `devflow switch` | 切换工作项 | 切换工作项 + 自动恢复上下文 |
| `devflow list` | 查看工作项 | 状态总览 + 可选同步 Meegle 状态 |
| `devflow change` | 需求变更 | 状态回退 + CodeGraph 重新评估 + Meegle 更新 |
| `devflow knowledge` | 知识库 | 经验卡查询 / 添加 / 健康检查 |

---

## Meegle 集成说明

DevFlow 与 Meegle 的集成是**可选增强**，不影响离线使用。

### 工作流映射

| DevFlow 阶段 | Meegle 操作 |
|------------|-----------|
| `start` | 创建工作项（可选） |
| `analyze` | 添加需求分析评论 |
| `code` | 流转至「开发中」 |
| `fix` | 读取 Bug 详情，流转至「已修复」，添加修复说明 |
| `review` | 流转至「待合并」，添加审查结论 |
| `retrospect` | 关闭工作项 |

### 查看 Meegle skill 文档

所有 Meegle API 调用方式参见 [references/meegle-integration.md](references/meegle-integration.md)。

---

## 安全分级

| 级别 | 适用模块 | AI 权限 |
|------|---------|---------|
| **L0** | 核心交易/支付/账户/权限 | 仅辅助分析，代码修改必须人工执行 |
| **L1** | 业务核心模块 | AI 可辅助，HIGH/CRITICAL 必须人工确认 |
| **L2** | 基础设施/工具/UI 组件 | AI 可全量辅助 |

---

## 目录结构

```
.devflow/
├── workspace.json              # 当前上下文（currentWorkItem + Meegle 配置）
├── config/
│   ├── devflow.json            # 状态机配置
│   ├── ai-policy.json          # AI 安全策略
│   ├── repo-classification.json
│   └── templates/
│       ├── requirement.tpl.md
│       ├── design.tpl.md
│       ├── tasks.tpl.md
│       ├── progress.tpl.md
│       ├── meta.tpl.json
│       └── knowledge/
│           └── bug-experience-cards.csv  # 内置 20 条 Bug 经验卡
├── work-items/
│   └── {YYYYMMDD}-{slug}/
│       ├── meta.json           # 状态机（含 linkedMeegleId）
│       ├── context/
│       │   ├── raw.md
│       │   └── sanitized.md
│       ├── spec/
│       │   ├── requirement.md
│       │   ├── design.md
│       │   └── api.md
│       ├── tasks.md
│       ├── progress.md         # Context Checkpoint
│       └── review.md
└── doc/
    ├── architecture/
    ├── conventions/
    ├── ai/
    └── adr/
```
