# Changelog

## v3.5.0 — 2026-08-19

### 工程化鲁棒性增强

本版本为 DevFlow 引入**双层工程化保障**，将"AI 自述"升级为"独立机械记录 + AI 语义补充"的组合，覆盖审计、状态约束、断点回滚三个维度。

#### 独立审计日志

- 新增 `devflow-audit.sh`（PostToolUse hook）：由 Claude Code 宿主进程独立执行，每次 AI 工具调用后将工具名、文件路径、时间戳追加到 `.devflow/audit-log.jsonl`，完全不依赖 AI 自述
- 新增 `devflow audit` 子命令：合并 `audit-log.jsonl`（hook 独立记录）和 `progress.md [DECISION]` 条目，输出阶段轨迹、文件操作统计、关键决策和被拦截操作；支持 `--tail 25 / --blocked / --decisions / {workItemId}` 四种过滤模式
- 非 Claude Code 平台（Cursor / Codex / OpenCode）自动降级为软约束模式，`devflow audit` 仍可用，但数据来源仅限 `progress.md`

#### 状态机硬拦截

- 新增 `devflow-state-guard.sh`（PreToolUse hook）：在 AI 写入文件前校验 `meta.json.status`，非法跃迁由宿主进程直接拦截（exit 1），同时向 `audit-log.jsonl` 写入拦截事件
- 状态-文件映射：`analyzing → requirement.md`、`designing → design.md`、`planning → tasks.md`、`coding → progress.md/tasks.md`、`reviewing → review.md`
- Bug 类型工作项（`type=bug`）自动跳过 spec 文件拦截，维持 Bug 修复简化流程不变

#### 断点 Checkpoint 与回滚

- `devflow-state-guard.sh` 在每次合法写入前自动将 `meta.json` 快照到 `checkpoints/meta-{时间戳}.json`，保留最近 10 份，零 token 消耗
- `devflow continue` 增强步骤 4：读取 `progress.md` 最后 25 条结构化条目（每条以 `[TAG]` 起始行为单元）检测中断，发现异常时展示三选项：继续当前状态 / 回滚到 checkpoint / 查看 audit 日志

#### 结构化执行日志规范

- 更新 `progress.md` 模板，新增文件头 `STATE_MACHINE` 注释、ISO 8601 UTC 时间戳规范、`[READ]` 粒度说明、`[TRANSITION]` 依据说明
- 全部 8 个执行命令（analyze / design / estimate / plan / code / review / retrospect / fix）统一新增「状态验证」和「执行日志规范」两个标准区块，前者扩展前置条件的错误格式，后者规范各命令的日志追加行为
- `devflow init` 新增步骤 6.5：平台检测（优先级：`CLAUDE_CODE` 环境变量 → `workspace.json.platform`），Claude Code 平台自动安装 hook 脚本并更新 `.claude/settings.json`

---

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
