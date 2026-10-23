# DevFlow Bootstrap Prompts

把对应平台的提示词粘贴到 AI CLI **第一条消息**，AI 会自动完成安装并在当前会话立即生效。

---

## OpenCode

```
你现在需要完成以下任务，按顺序执行，每步完成后继续下一步，不要等待我确认：

**步骤 1：安装 DevFlow**
运行命令：
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --platform opencode --yes

如果无法访问 GitHub，改用内网：
git clone http://gitlab.inzwc.com/hst-sa/app-team/devflow.git _df_tmp && bash _df_tmp/install.sh --platform opencode --yes && rm -rf _df_tmp

**步骤 2：建立代码索引**
检查 codegraph 是否可用（运行 `codegraph --version`）：
- 可用 → 运行 `codegraph init`
- 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`

**步骤 3：初始化项目**
运行：devflow init

**步骤 4：激活工作流**
安装完成后，读取 `OPENCODE.md` 文件，从现在起按其中的命令路由规则响应用户输入。

全部完成后回复"✅ DevFlow 已就绪，可以开始工作了"，然后等待我的下一条指令。
```

---

## Codex

```
你现在需要完成以下任务，按顺序执行，每步完成后继续下一步，不要等待我确认：

**步骤 1：安装 DevFlow**
运行命令：
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --platform codex --yes

如果无法访问 GitHub，改用内网：
git clone http://gitlab.inzwc.com/hst-sa/app-team/devflow.git _df_tmp && bash _df_tmp/install.sh --platform codex --yes && rm -rf _df_tmp

**步骤 2：建立代码索引**
检查 codegraph 是否可用（运行 `codegraph --version`）：
- 可用 → 运行 `codegraph init`
- 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`

**步骤 3：初始化项目**
运行：devflow init

**步骤 4：激活工作流**
安装完成后，读取 `AGENTS.md` 文件，从现在起按其中的命令路由规则响应用户输入。

全部完成后回复"✅ DevFlow 已就绪，可以开始工作了"，然后等待我的下一条指令。
```

---

## Gemini CLI

```
你现在需要完成以下任务，按顺序执行，每步完成后继续下一步，不要等待我确认：

**步骤 1：安装 DevFlow**
运行命令：
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --platform gemini --yes

如果无法访问 GitHub，改用内网：
git clone http://gitlab.inzwc.com/hst-sa/app-team/devflow.git _df_tmp && bash _df_tmp/install.sh --platform gemini --yes && rm -rf _df_tmp

**步骤 2：建立代码索引**
检查 codegraph 是否可用（运行 `codegraph --version`）：
- 可用 → 运行 `codegraph init`
- 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`

**步骤 3：初始化项目**
运行：devflow init

**步骤 4：激活工作流**
安装完成后，读取 `GEMINI.md` 文件，从现在起按其中的命令路由规则响应用户输入。

全部完成后回复"✅ DevFlow 已就绪，可以开始工作了"，然后等待我的下一条指令。
```

---

## Kiro CLI

```
你现在需要完成以下任务，按顺序执行，每步完成后继续下一步，不要等待我确认：

**步骤 1：安装 DevFlow**
运行命令：
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --platform kiro --yes

如果无法访问 GitHub，改用内网：
git clone http://gitlab.inzwc.com/hst-sa/app-team/devflow.git _df_tmp && bash _df_tmp/install.sh --platform kiro --yes && rm -rf _df_tmp

**步骤 2：建立代码索引**
检查 codegraph 是否可用（运行 `codegraph --version`）：
- 可用 → 运行 `codegraph init`
- 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`

**步骤 3：初始化项目**
运行：devflow init

**步骤 4：激活工作流**
安装完成后，读取 `.kiro/steering/devflow.md` 文件，从现在起按其中的命令路由规则响应用户输入。

全部完成后回复"✅ DevFlow 已就绪，可以开始工作了"，然后等待我的下一条指令。
```

---

## 通用版（不确定平台时使用）

```
你现在需要完成以下任务，按顺序执行，每步完成后继续下一步，不要等待我确认：

**步骤 1：安装 DevFlow**
运行命令：
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinhaha/devflow/main/install.sh) --yes

--yes 会自动检测当前平台（codex / opencode / gemini / kiro / cursor / claude）并跳过交互确认。
如果无法访问 GitHub，改用内网：
git clone http://gitlab.inzwc.com/hst-sa/app-team/devflow.git _df_tmp && bash _df_tmp/install.sh --yes && rm -rf _df_tmp

**步骤 2：建立代码索引**
检查 codegraph 是否可用（运行 `codegraph --version`）：
- 可用 → 运行 `codegraph init`
- 不可用 → 运行 `npm install -g @colbymchenry/codegraph && codegraph init`

**步骤 3：初始化项目**
运行：devflow init

**步骤 4：激活工作流**
安装完成后，按优先级查找并读取以下文件之一（取第一个存在的）：
- OPENCODE.md
- AGENTS.md
- GEMINI.md
- .kiro/steering/devflow.md
- .cursor/rules/devflow.mdc

从现在起按该文件中的命令路由规则响应用户输入。

全部完成后回复"✅ DevFlow 已就绪，可以开始工作了"，然后等待我的下一条指令。
```

---

## 说明

- 每段提示词都是**自驱动的**：AI 读到后立刻执行安装、索引、初始化，完成后自动切换到 DevFlow 路由规则
- 步骤 4 的"读取并激活"让当前会话立即生效，无需重启工具
- CodeGraph 只需全局装一次（`npm install -g @colbymchenry/codegraph`），多个项目、多个工具共用同一个命令
- 内网版将 GitHub URL 替换为 GitLab 地址即可，其余完全相同
