# Changelog

## v3.3.0 — 2026-08-12

### 开源清洁化

- 去除所有内部品牌信息，仓库完全对外开放
- YApi 域名、专项 Skill 名称等环境配置移入 `.devflow/workspace.json`（已 gitignore），仓库保持干净

### `devflow init` 新增外部集成配置

初始化时可选填写外部服务地址，写入本地 `workspace.json`，不提交仓库：

- **YApi 域名**（`integrations.yapiHost`）：analyze / design 命令自动读取，未配置时跳过 YApi 步骤
- **验收清单 Skill 名**（`checklistSkill`）：checklist 命令优先使用，未配置时降级通用规范

### Worktree 并行开发

`devflow code` 默认在独立 worktree 中执行，支持多需求并行开发：

```bash
devflow code              # 默认，自动创建 worktree
devflow code noworktree   # 在当前工作区直接编码
```

`workspace.json` 升级为多工作项并行结构（`focus` + `activeWorkItems`），`devflow switch` / `continue` / `list` 全部感知并行状态。

### `devflow checklist` — 真机验收清单

基于需求文档和设计文档生成可直接交付测试的结构化清单，包含进入路径、Mock 接口表格、逐条 AC 检查点和回归验证表。

### `devflow review` 委托专项 skill

优先读取 `workspace.json.reviewSkills` 中配置的专项 review skill，按 diff 特征自动匹配；无匹配时降级通用四维度审查，CRITICAL 阻断合并。审查通过后支持直接合并或提 MR/PR。

### 多工程 / 多仓库支持

`devflow init` 自动识别项目结构并生成对应 CodeGraph 索引策略：

| 项目类型 | 索引策略 |
|---------|---------|
| Android / KMP 壳工程 + submodules | 单根索引 |
| iOS CocoaPods 含本地 path Pod | 多根索引 |
| 完全独立多仓库 | 多根索引 |
| 单仓库 | 单根索引 |

新增 `devflow-cg` 脚本处理多根路由，CodeGraph 调用不再占用 LLM 推理资源。

### `devflow quick` 三路径自动判断

根据 CodeGraph 影响符号数自动选择执行路径：

| 路径 | 触发条件 | 典型场景 |
|------|---------|---------|
| 极简 | 影响 ≤ 3 个符号 | 文案修改、配置项调整 |
| 快速 | 影响 4–10 个符号，无新增接口 | 小 UI 改动 |
| 完整 | 影响 > 10 个符号，或需新增接口 | 架构变更、新功能 |
