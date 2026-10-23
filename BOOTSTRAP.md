# DevFlow Bootstrap Prompts

把对应的提示词粘贴到 AI CLI 的**第一条消息**，AI 会自动完成安装并准备好工作流。

---

## 外网版（GitHub）

适用于 Codex、OpenCode、Gemini CLI、Kiro CLI 等任何支持执行 shell 的 AI CLI。

````
请立刻在当前目录执行以下 shell 命令，不要跳过任何步骤，全部完成后告诉我结果：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --yes
```

`--yes` 会自动检测当前平台并跳过交互确认。安装完成后：
1. 如果 `.codegraph/` 目录不存在，检查 `codegraph` 命令是否可用：
   - 可用 → 运行 `codegraph init`
   - 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`
2. 运行 `devflow init` 完成项目初始化

全部完成后告诉我，我们开始第一个需求。
````

---

## 内网版（GitLab，无外网访问）

````
请立刻在当前目录执行以下 shell 命令，不要跳过任何步骤，全部完成后告诉我结果：

```bash
git clone http://gitlab.inzwc.com/hst-sa/app-team/devflow.git devflow-tmp \
  && bash devflow-tmp/install.sh --yes \
  && rm -rf devflow-tmp
```

`--yes` 会自动检测当前平台并跳过交互确认。安装完成后：
1. 如果 `.codegraph/` 目录不存在，检查 `codegraph` 命令是否可用：
   - 可用 → 运行 `codegraph init`
   - 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`
2. 运行 `devflow init` 完成项目初始化

全部完成后告诉我，我们开始第一个需求。
````

---

## 说明

**`--yes` 做了什么：**  
自动检测平台（Codex / Kiro CLI / OpenCode / Gemini / Claude Code 等），跳过「使用此平台？」的交互确认，静默安装。检测顺序：kirocrew → kiro → cursor → codex → opencode → gemini → claude。

**安装脚本自动完成：**
- 20 个命令文件 → `.devflow/commands/`
- 平台适配器（Steering File / AGENTS.md / Skills 等）
- CodeGraph MCP 配置（对应工具的 mcp.json）
- `.gitignore` 更新

**CodeGraph：**  
只需装一次（`npm install -g @colbymchenry/codegraph`），所有 AI 工具共用同一份项目索引（`.codegraph/`），不需要重装。
