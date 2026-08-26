<p align="center">
  <img src="https://img.shields.io/badge/DevFlow-3.8.0-63b3ed?style=for-the-badge&labelColor=0d1829" alt="DevFlow" />
  <img src="https://img.shields.io/badge/platform-Kiro-68d391?style=for-the-badge&labelColor=0d1829" alt="Kiro" />
</p>

<h1 align="center">DevFlow × Kiro</h1>
<p align="center">给 Kiro 补上完整研发闭环——从需求分析到经验入库，20 个命令覆盖 SDLC 全流程</p>

<br/>

## 为什么在 Kiro 上用 DevFlow

Kiro 的 Spec 记录了意图，但回答不了「这个函数改了会影响谁」。DevFlow 补上这块缺口：

| 你遇到的问题 | DevFlow 的解法 |
|------------|--------------|
| 改代码不知道影响范围 | `devflow design` 用 CodeGraph 算爆炸半径，HIGH/CRITICAL 自动触发确认门禁 |
| Bug 修了又出现，经验丢失 | `devflow fix` 强制四阶段根因分析，修完自动提炼经验卡入库 |
| 新对话丢失上下文 | `devflow continue` 读取 Checkpoint，一条命令恢复所有进度 |
| Spec 和代码悄悄跑偏 | `devflow change` 变更时自动回退受影响任务并写入回归义务 |

---

## 安装

在**项目根目录**运行：

```bash
# 内网（推荐）
bash <(curl -fsSL http://gitlab.inzwc.com/hst-sa/app-team/devflow/-/raw/main/install.sh) --platform kiro
# 外网
bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh) --platform kiro
```

脚本自动完成：命令文件安装 → Steering File 写入 `.kiro/steering/devflow.md` → `.gitignore` 更新。

安装后在 Kiro 中运行一次初始化（每个项目只需一次）：

```
devflow init
```

升级：`bash <(curl -fsSL http://gitlab.inzwc.com/hst-sa/app-team/devflow/-/raw/main/install.sh) --update`（内网）  或  `bash <(curl -fsSL https://raw.githubusercontent.com/lyxiinnaha/devflow/main/install.sh) --update`（外网）

---

## 核心工作流

**新功能（完整流程）：**

```
devflow start <需求描述>   # 创建工作项
devflow analyze            # 边贴材料边解析，支持 PRD / 截图 / Figma / YApi 链接
devflow design             # 技术方案 + 爆炸半径评估
devflow plan               # 拆解为原子任务
devflow code               # 逐任务实现，内置 L0 安全门禁
devflow review             # 四维度审查，CRITICAL 阻断合并
devflow retrospect         # 经验入库，关闭工作项
```

**小改动（一条命令）：**

```
devflow quick 详情页右上角加分享按钮
```

AI 自动判断路径：≤ 2 个文件直接编码，影响面大时自动转完整流程。

**修 Bug：**

```
devflow fix 点击提交按钮后页面白屏，报 TypeError: Cannot read ...
devflow fix https://project.feishu.cn/xxx/issue/12345678   # 或直接贴 Meegle 链接
```

**恢复进度：**

```
devflow continue   # 新对话 / 重开 Kiro 后，读取 Checkpoint 恢复上次状态
```

---

## Kiro 特有说明

**Steering File 自动加载**：安装后 `.kiro/steering/devflow.md` 带有 `inclusion: always`，每次对话无需手动引入。

**CodeGraph MCP（推荐）**：在 Kiro MCP 配置中添加后，`design` / `fix` / `review` 的分析精度显著提升。`devflow init` 会自动引导配置，也可以手动添加：

```json
{
  "mcpServers": {
    "codegraph": { "command": "codegraph", "args": ["mcp"] }
  }
}
```

**与 Kiro Spec 的关系**：两者互补。Kiro Spec 是设计意图的静态文档；DevFlow 的 `.devflow/work-items/` 是带状态机的执行记录，记录每次决策、变更和经验。可以同时用，也可以只用其中一套。

---

<p align="center">完整命令文档见 <a href="./README.md">主 README</a> · 问题反馈 <a href="../../issues">GitHub Issue</a></p>
