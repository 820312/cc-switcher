---
name: cc-switcher
description: |
  Use when: 用户要操作任何第三方模型提供商（小米/DeepSeek/OpenRouter/Gemini/MiniMax/智谱等），包括：首次配置、添加新提供商、删除提供商、更新模型。触发词包括但不限于："配置模型"、"更新模型"、"添加提供商"、"模型过期"、"第三方 API"、"切换模型提供商"、"cc 命令"。
  DO NOT use when: 用户只是在问 Claude 模型的能力对比，或只是切换 /model 而不涉及 API Key 配置。
---

## 意图判断

**在做任何事之前**，判断属于哪种场景：

- **首次配置**：`PROVIDERS_DIR` 不存在，或 `LAUNCH_SCRIPT` 不存在
- **添加新提供商**：目录和脚本已存在，用户只需新增一个 provider 文件
- **删除提供商**：用户提到"删除"、"移除"、"卸载"某个提供商
- **更新模型**：用户提到"更新模型"、"更新配置"、"模型过期"

**平台检测**：读取系统上下文的 `Platform` 字段——`darwin`/`linux` → macOS/Linux 分支；`win32` → Windows 分支。**每步只向用户展示对应平台的命令。**

## 平台路径定义

| 变量 | macOS / Linux | Windows |
|------|--------------|---------|
| `PROVIDERS_DIR` | `~/.claude/providers/` | `%USERPROFILE%\.claude\providers\` |
| `LAUNCH_SCRIPT` | `~/.claude/launch.sh` | `%USERPROFILE%\.claude\launch.ps1` |
| `SKILL_SCRIPT` | `~/.claude/skills/cc-switcher/scripts/launch.sh` | `%USERPROFILE%\.claude\skills\cc-switcher\scripts\launch.ps1` |
| `SETTINGS` | `~/.claude/settings.json` | `%USERPROFILE%\.claude\settings.json` |
| `ONBOARDING` | `~/.claude.json` | `%USERPROFILE%\.claude.json` |

---

## 通用流程

### [模型查询与推荐]

1. **联网获取模型信息**（不向用户询问）：获取 `ANTHROPIC_BASE_URL`、模型文档页 URL 及各档位模型 ID，**必须从官方文档获取，不得猜测**
2. **展示模型列表**：整理成表格（含模型名、上下文窗口、特点），最多展示 5 个主要模型
3. **给出推荐**：按 Anthropic 档位定义（见参考部分）筛选 3 个型号：
   - **Opus** → 最强旗舰 · **Sonnet** → 性价比主力 · **Haiku** → 最快最便宜
4. 展示后说：「这是基于 Anthropic 档位定义的推荐，如有不同需求可以调整。」

### [alias 检查]

检查 shell 配置中是否已有 `cc` alias/function，不存在则添加：
- **macOS/Linux**：检查 `~/.zshrc` 是否包含 `alias cc=`，否则 `echo "alias cc='~/.claude/launch.sh'" >> ~/.zshrc && source ~/.zshrc`
- **Windows**：检查 `$PROFILE` 是否包含 `function cc`，否则追加 `function cc { & "$env:USERPROFILE\.claude\launch.ps1" @args }`

### [完成提示]

> 以后请通过输入 `cc` 启动 Claude Code，脚本会列出所有提供商供你选择。
> 需要透传参数时直接附加，例如：`cc --yolo`（等价于 `cc --dangerously-skip-permissions`）
> **注意**：`cc` 会将提供商配置写入全局 settings.json，所有终端共享同一提供商。如需切换提供商，重新运行 `cc` 即可。

---

## 工作流 A：首次配置

**= 环境初始化 + 工作流 B**

### 环境初始化（B 之前执行）

1. **静默操作**：编辑或新增 `ONBOARDING` 文件，确保包含 `"hasCompletedOnboarding": true`（不存在则创建，已存在则追加字段）
2. **创建目录**：`mkdir -p PROVIDERS_DIR`（Windows：`New-Item -ItemType Directory -Force`）
3. **执行工作流 B**（添加提供商）
4. **复制启动脚本**：`cp SKILL_SCRIPT LAUNCH_SCRIPT`
   - macOS/Linux 依赖 `fzf` 和 `jq`，未安装先 `brew install fzf jq`
   - Windows 无需额外工具，`fzf` 可选
5. **赋予执行权限**：macOS/Linux `chmod +x LAUNCH_SCRIPT` · Windows `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
6. **执行 [alias 检查]**
7. **展示 [完成提示]**

---

## 工作流 B：添加新提供商

1. **执行 [模型查询与推荐]**
2. **索要 API Key**：展示推荐配置方案，然后说："请提供你的 [提供商名] API Key。"
3. **创建配置文件**（按末尾「参考：配置文件格式」，将模型文档页 URL 写入顶层 `docs_url` 字段）：`PROVIDERS_DIR/<公司名>.json`，文件名用**公司名**大小写
4. **执行 [alias 检查]**
5. **展示 [完成提示]**，补充：`launch.sh` / `launch.ps1` 动态扫描 providers 目录，新建文件后直接运行 `cc` 即可看到新条目

---

## 工作流 C：删除提供商

1. **静默检测活跃冲突**：比对待删除 provider 文件名与 `LAUNCH_SCRIPT` 最近一次选择（可通过检查当前终端进程的 `--settings` 参数判断）
2. **若冲突** → 提示：「你当前正在使用 [模型名称]，确认删除吗？」等待确认
3. **删除** `PROVIDERS_DIR/<公司名>.json`
4. **告知用户**：「[提供商名] 已删除。」若有冲突补充：「下次运行 `cc` 时选择其他提供商即可。」

---

## 工作流 D：更新模型

1. **确定提供商**：用户明确了则直接用，否则询问
2. **获取最新模型**：
   - provider 文件中有 `docs_url` → **直接抓取**该页面
   - 无 `docs_url` → 联网搜索官方文档页，获取后**补写回** provider 文件
   - 最多展示 5 个主要模型，按 Opus/Sonnet/Haiku 给出推荐
   - **必须从官方文档获取，不得猜测模型名**
3. **判断是否有新版本**：
   - 有 → 展示当前 vs 最新对比，询问是否更新
   - 无 → 告知「当前配置已是最新」
4. **执行更新**：保留 API Key 不变，只更新 5 个 `ANTHROPIC_*_MODEL` 字段，告知「重新运行 `cc` 即可使用新模型」

---

## 参考：配置文件格式

```json
{
  "docs_url": "<提供商模型文档页 URL>",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<API Key>",
    "ANTHROPIC_BASE_URL": "<Anthropic 兼容端点>",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "<轻量模型ID>",
    "ANTHROPIC_SMALL_FAST_MODEL": "<轻量模型ID>",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "<旗舰模型ID>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<主力模型ID>",
    "ANTHROPIC_MODEL": "<主力模型ID>",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

**Anthropic 档位定义**：Opus = 最强旗舰（复杂推理）· Sonnet = 速度与智能平衡（日常主力）· Haiku = 最快最便宜（高吞吐）

| 字段 | 用途 |
|------|------|
| `docs_url` | 提供商模型列表页 URL（顶层字段，不在 `env` 内，不写入 settings.json） |
| `ANTHROPIC_AUTH_TOKEN` | API Key（Anthropic 官方可省略；第三方必填） |
| `ANTHROPIC_BASE_URL` | 提供商的 Anthropic 兼容端点 |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | 轻量任务（后台操作、自动补全） |
| `ANTHROPIC_SMALL_FAST_MODEL` | 同 Haiku，部分版本使用此字段名，两者同时填写保证兼容 |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | 主对话（日常默认档位） |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | 复杂任务（用户手动选择时） |
| `ANTHROPIC_MODEL` | 总默认值，通常与 Sonnet 一致 |

提供商只有一个模型时，四个模型字段填同一值即可。