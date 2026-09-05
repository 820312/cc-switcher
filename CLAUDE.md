# cc-switcher

在 Claude Code 中快速切换 AI 提供商的 skill。

## 目录结构

```
cc-switcher/
├── SKILL.md            # skill 定义（Claude Code 加载入口）
├── scripts/
│   ├── launch.sh       # macOS / Linux
│   └── launch.ps1      # Windows
├── CLAUDE.md           # 项目说明（本文件）
├── README.md           # 面向用户的文档
└── .gitignore
```

## 开发约定

- `SKILL.md` 是 Claude Code 加载入口
- 需要脚本的 skill 放在 `scripts/` 子目录
- `README.md` 面向用户，只写使用说明，不写技术细节
- `plan/` 放开发计划和设计文档，不进 git
- skill 更新完成后，询问用户是否需要同步到 Claude Code 技能目录，需要则执行：`cp -r <skill-dir> ~/.claude/skills/`
