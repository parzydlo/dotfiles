#!/usr/bin/env bash
input=$(cat)
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")
branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

parts="$dir"
[ -n "$branch" ] && parts="$parts  $branch"
parts="$parts  $model"
[ -n "$used" ] && parts="$parts  ctx:$(printf '%.0f' "$used")%"

printf '%s' "$parts"
