#!/bin/bash
# Claude Code status line. Receives session JSON on stdin.
# Renders: model | directory branch | +added/-removed | cost

input=$(cat)

dim=$'\033[2m'
cyan=$'\033[36m'
magenta=$'\033[35m'
green=$'\033[32m'
red=$'\033[31m'
yellow=$'\033[33m'
reset=$'\033[0m'
sep="${dim} | ${reset}"

get() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

model=$(get '.model.display_name')
cwd=$(get '.workspace.current_dir')
[ -z "$cwd" ] && cwd=$(get '.cwd')
added=$(get '.cost.total_lines_added')
removed=$(get '.cost.total_lines_removed')
cost=$(get '.cost.total_cost_usd')

out=""
[ -n "$model" ] && out="${cyan}${model}${reset}"

if [ -n "$cwd" ]; then
    [ -n "$out" ] && out="${out}${sep}"
    out="${out}${dim}$(basename "$cwd")${reset}"

    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        dirty=""
        [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] && dirty="${yellow}*${reset}"
        out="${out} ${magenta}${branch}${reset}${dirty}"
    fi
fi

if [ -n "$added" ] || [ -n "$removed" ]; then
    if [ "${added:-0}" -gt 0 ] 2>/dev/null || [ "${removed:-0}" -gt 0 ] 2>/dev/null; then
        out="${out}${sep}${green}+${added:-0}${reset}${dim}/${reset}${red}-${removed:-0}${reset}"
    fi
fi

if [ -n "$cost" ]; then
    formatted=$(printf '%.2f' "$cost" 2>/dev/null)
    if [ -n "$formatted" ] && [ "$formatted" != "0.00" ]; then
        out="${out}${sep}${yellow}\$${formatted}${reset}"
    fi
fi

printf '%s' "$out"
