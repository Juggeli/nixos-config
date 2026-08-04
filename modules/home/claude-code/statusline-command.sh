#!/bin/sh
# Claude Code status line

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')

# Context window usage
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Get just the last directory name
dir_name=$(basename "$cwd")

# Git branch
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" -c core.fsync=none symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && git_branch="$branch"
fi

# Calculate used tokens and format compactly
used_tokens=$(( ctx_size * ctx_used / 100 ))
if [ "$used_tokens" -ge 1000000 ] 2>/dev/null; then
    major=$((used_tokens / 1000000))
    minor=$(( (used_tokens % 1000000) / 100000 ))
    if [ "$minor" -gt 0 ]; then
        token_display="${major}.${minor}m"
    else
        token_display="${major}m"
    fi
elif [ "$used_tokens" -ge 1000 ] 2>/dev/null; then
    token_display="$((used_tokens / 1000))k"
else
    token_display="${used_tokens}"
fi

printf "› %s  ∙  ⎇ %s  ∙  ◈ %s (%s%%)" "$dir_name" "$git_branch" "$token_display" "$ctx_used"
