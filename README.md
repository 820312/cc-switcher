# cc-switcher

在 Claude Code 中快速切换 AI 提供商，支持 Anthropic、DeepSeek、Qwen、OpenRouter、Gemini 等任意 Anthropic 兼容 API。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgray.svg)

## 安装

```bash
git clone https://github.com/820312/cc-switcher.git
mkdir -p ~/.claude/skills
cp -r cc-switcher ~/.claude/skills/
```

macOS / Linux 使用 `cc-switcher` 需要 `fzf` 和 `jq`：

```bash
brew install fzf jq
```

Windows 无强制依赖，`fzf` 可选。

## 使用

在 Claude Code 中说：

- **首次配置**：「帮我配置 Claude Code 提供商」或「我想用 DeepSeek」
- **添加提供商**：「帮我添加 OpenRouter」
- **删除提供商**：「删除 OpenRouter」
- **更新模型**：「帮我更新 DeepSeek 的模型」

配置完成后，终端运行 `cc` 即可通过交互菜单选择提供商启动 Claude Code。

```bash
cc
cc --yolo
```

`cc --yolo` 等价于 `cc --dangerously-skip-permissions`。

## 配置文件格式

`~/.claude/providers/<公司名>.json`：

```json
{
  "docs_url": "<提供商模型文档页 URL>",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<API Key>",
    "ANTHROPIC_BASE_URL": "<Anthropic 兼容端点>",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "<轻量模型 ID>",
    "ANTHROPIC_SMALL_FAST_MODEL": "<轻量模型 ID>",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "<旗舰模型 ID>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<主力模型 ID>",
    "ANTHROPIC_MODEL": "<主力模型 ID>",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

## 许可证

MIT License
