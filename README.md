# DevFlow v3.0.0 — AI-Native 研发工作流

> 从需求到交付的全流程 AI 辅助研发工作流。深度集成 **CodeGraph 知识图谱 + Meegle 项目管理 + Figma + YApi**，内置状态机、安全分级、强制复盘和 Context Checkpoint，构建自我进化的研发闭环。

---

## 快速开始

### 第一步：安装插件

```bash
claude plugins install devflow
```

### 第二步：初始化项目（每个项目只需一次）

```
devflow init
```

AI 自动完成：检查 CodeGraph / Meegle 状态、建立 `.devflow/` 目录、写入 `.gitignore`、确认安全分级。

### 第三步：开始开发

```
devflow start 用户头像上传 支持裁剪和预览
devflow fix https://project.feishu.cn/...
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

## 17 个命令

| 命令 | 核心能力 |
|------|---------|
| `devflow init` | 配置 CodeGraph + Meegle，建立工作区，写入 .gitignore |
| `devflow start` | 创建工作项，进入需求收集模式（Intake Mode） |
| `devflow analyze` | 边录边析：逐段输入即时解析，读 Figma / YApi，CodeGraph 反查现有接口 |
| `devflow design` | 爆炸半径评估，边设计边追问，生成内部设计文档 + 对外技术方案文档 |
| `devflow estimate` | 三点置信区间估算，历史 Bug 密度因子，可更新 Meegle 排期 |
| `devflow plan` | 标准化任务格式，Bug 经验召回，静默输出 tasks.md |
| `devflow code` | 执行范围选择，编码禁令，lint/test 质量门禁 |
| `devflow fix` | Meegle issue 批量处理，90 分准入门禁，人工验证后提交 |
| `devflow refactor` | 测试基线验证，重构后一致性断言 |
| `devflow review` | 四维度审查，CRITICAL 阻断合并 |
| `devflow retrospect` | 经验卡去重入库，关闭 Meegle 工作项 |
| `devflow onboard` | CodeGraph 架构导览，历史 Bug 热点，Meegle 近期工作项 |
| `devflow continue` | 读取 Checkpoint，新会话快速恢复，展示 Meegle 状态 |
| `devflow switch` | 切换工作项，自动恢复上下文 |
| `devflow list` | 状态总览，Active/Paused/Completed 分组 |
| `devflow change` | Minor/Major 变更分级，状态机回退，受影响任务标记返工 |
| `devflow knowledge` | 结构化查询，健康检查，JSON 导出 |

---

## MCP 依赖

| MCP | 必须/可选 | 说明 |
|-----|---------|------|
| `codegraph` | 必须 | 代码知识图谱，爆炸半径分析 |
| `meegle` | 可选 | 项目管理，工作项全生命周期联动 |
| `Framelink MCP for Figma` | 可选 | 需求分析阶段读取设计稿 |
| `YApi` | 可选 | WebFetch 读取接口定义（`yapi.hszq8.com`） |

---

## 目录结构

```
plugins/devflow/
├── .claude-plugin/plugin.json   # 插件元数据
├── commands/                    # 17 个命令（含 SKILL.md frontmatter，支持自动触发）
├── assets/
│   ├── config/                  # devflow.json、ai-policy.json、分级配置
│   └── templates/               # 文档模板 + bug-experience-cards.csv（20 条内置经验）
└── references/
    └── meegle-integration.md    # Meegle CLI 调用速查
```
