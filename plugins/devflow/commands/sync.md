---
name: devflow-sync
description: DevFlow 团队 AI 文件同步。将 devflow 插件包中的团队公共 skills/agents 同步到当前项目，创建软链接，维护 .gitignore。当用户说「同步 AI 文件」「devflow sync」「安装团队 skill」「更新 skill」时触发。
---

# devflow sync — 团队 AI 文件同步

**用途：** 将 devflow 插件包中维护的团队公共 skills 和 agents 同步到当前项目的 `.ai/` 目录，创建 `.claude/skills`、`.codex/skills` 软链接，并维护 `.gitignore` 中的个人 AI 配置忽略规则。

---

## 何时使用

- 首次在项目中使用 devflow，需要安装团队公共 skill
- devflow 插件升级后，需要将新版 skill 同步到各项目
- 新成员加入，需要快速配置本地 AI 工具环境
- 用户提到「同步 skill」「安装 AI 文件」「更新 skill」

---

## 前置条件

- 必须在项目根目录执行（基于 README、构建配置、包管理文件或源码目录判断）
- devflow 插件已安装（`claude plugins install devflow`）

---

## 执行步骤

### 1. 确认项目根目录

若当前目录不像项目根目录，提示用户切换后再继续，不猜测。

### 2. 定位同步脚本

脚本随插件存放在 `skills/devflow-sync/sync-ai-files.sh`（相对于本 skill 所在目录）。

若无法定位脚本，提示用户重新安装 devflow 插件：
```
✗ 无法定位 sync-ai-files.sh。
  请执行 claude plugins install devflow 重新安装后重试。
```

### 3. 调用同步脚本

```bash
bash <devflow-sync-skill-dir>/sync-ai-files.sh <target-project-root>
```

### 4. 验证同步结果

检查以下内容是否正确：
- `.ai/skills/` 已创建并包含同步的 skill 文件
- `.claude/skills/` 下的软链接指向 `.ai/skills/`
- `.codex/skills/` 下的软链接指向 `.ai/skills/`（若 `.codex/` 存在）
- `.gitignore` 包含个人 AI 配置忽略 block

---

## 输出

```
✅ 团队 AI 文件已同步

  Skills：
    源目录：{devflow插件路径}/ai-files/skills
    目标目录：{项目根目录}/.ai/skills
    已同步：{n} 个 skill

  工具链接：
    .claude/skills/ ✓
    .codex/skills/  ✓（或「目录不存在，已跳过」）

  .gitignore：已更新（添加个人 AI 配置忽略规则）
  Git index：已清理被跟踪的个人 AI 配置（如有）
```
