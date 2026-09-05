#!/bin/bash

echo -e "\n\033[1;34m  Select Provider\033[0m"

# 简写参数展开
args=()
for arg in "$@"; do
  case "$arg" in
    --yolo) args+=("--dangerously-skip-permissions") ;;
    *)      args+=("$arg") ;;
  esac
done
set -- "${args[@]}"

PROVIDERS_DIR=~/.claude/providers

# 动态扫描 providers 目录，构造 "名称  模型" 格式的选项列表
options=$(
  for f in "$PROVIDERS_DIR"/*.json; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .json)
    model=$(jq -r '.env.ANTHROPIC_MODEL // "unknown"' "$f" 2>/dev/null)
    printf "%-12s %s\n" "$name" "$model"
  done
)

if [ -z "$options" ]; then
  echo "No providers found in $PROVIDERS_DIR" >&2
  exit 1
fi

config=$(echo "$options" | fzf \
  --prompt="" \
  --header=$'Switch between providers. Applies to this and future Claude Code sessions.\n' \
  --header-first \
  --height=10 \
  --no-border \
  --padding="0,2" \
  --layout=reverse \
  --no-info \
  --separator="" \
  --pointer=" " \
  --preview='echo ""' \
  --preview-window='down:1:noborder' \
  --color="header:gray,hl:blue,hl+:blue,bg+:-1,fg+:blue,pointer:blue,preview-bg:-1,preview-fg:240" \
  --bind="load:+change-preview(echo '  Enter to confirm · Esc to exit')" \
  | awk '{print $1}')

[ -z "$config" ] && exit 1

[ -f ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json

tmp=$(mktemp)
jq -s '.[0] * {"env": .[1].env}' \
  ~/.claude/settings.json \
  ~/.claude/providers/$config.json \
  > "$tmp" \
  && mv "$tmp" ~/.claude/settings.json

echo "Switched to $config, starting Claude Code..."
claude "$@"
