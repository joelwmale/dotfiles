#!/bin/bash
# Claude Code status line. Receives session JSON on stdin.
# Renders: model | dir branch | context% | 5h limit | 7d limit
#
# Limit segments read "5h 48% 1h32m·11:57am" - percentage of the window used,
# time remaining, and the wall-clock time it resets. Percentages are colour
# coded green under 50, yellow 50-79, red 80 and above.

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

# Percentages arrive as floats (56.99999999999999). Round to a whole number so
# they display sanely and survive integer comparison in pct_color.
round_pct() {
    case "$1" in
        ''|*[!0-9.]*) return ;;
    esac
    printf '%.0f' "$1" 2>/dev/null
}

# Colour for a 0-100 usage percentage: the higher the worse.
pct_color() {
    if   [ "$1" -ge 80 ] 2>/dev/null; then printf '%s' "$red"
    elif [ "$1" -ge 50 ] 2>/dev/null; then printf '%s' "$yellow"
    else printf '%s' "$green"
    fi
}

# Compact time until a unix timestamp: 4d3h / 2h14m / 9m.
until_ts() {
    local diff d h m
    diff=$(( $1 - $(date +%s) ))
    [ "$diff" -le 0 ] && { printf 'now'; return; }
    d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
    if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
    elif [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"
    else printf '%dm' "$m"
    fi
}

# Wall-clock time a timestamp falls on: "11:57am", or "Sat 10am" if not today.
# Minutes are omitted on the hour. For 24-hour clock, swap the %-I:%M/%-I
# formats below for %H:%M and drop $ampm.
at_ts() {
    local ts=$1 hhmm min ampm day=""
    min=$(date -r "$ts" "+%M" 2>/dev/null) || return
    if [ "$min" = "00" ]; then
        hhmm=$(date -r "$ts" "+%-I" 2>/dev/null)
    else
        hhmm=$(date -r "$ts" "+%-I:%M" 2>/dev/null)
    fi
    ampm=$(date -r "$ts" "+%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    [ "$(date -r "$ts" "+%Y%m%d" 2>/dev/null)" != "$(date "+%Y%m%d")" ] \
        && day="$(date -r "$ts" "+%a") "
    printf '%s%s%s' "$day" "$hhmm" "$ampm"
}

# "5h 48% 1h32m·11:57am", coloured by severity. $1=label $2=pct $3=reset ts
limit_segment() {
    local label=$1 pct=$2 ts=$3 c
    [ -z "$pct" ] && return
    c=$(pct_color "$pct")
    printf '%s%s %s%s%%%s' "$dim" "$label" "$c" "$pct" "$reset"
    [ -n "$ts" ] && printf ' %s%s%s%s%s' \
        "$dim" "$(until_ts "$ts")" "·" "$(at_ts "$ts")" "$reset"
}

out=""
add() { [ -n "$out" ] && out="${out}${sep}"; out="${out}$1"; }

model=$(get '.model.display_name')
[ -n "$model" ] && out="${cyan}${model}${reset}"

cwd=$(get '.workspace.current_dir'); [ -z "$cwd" ] && cwd=$(get '.cwd')
if [ -n "$cwd" ]; then
    seg="${dim}$(basename "$cwd")${reset}"
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        dirty=""
        [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] && dirty="${yellow}*${reset}"
        seg="${seg} ${magenta}${branch}${reset}${dirty}"
    fi
    add "$seg"
fi

ctx=$(round_pct "$(get '.context_window.used_percentage')")
[ -n "$ctx" ] && add "$(pct_color "$ctx")${ctx}%${reset}${dim} ctx${reset}"

five=$(round_pct "$(get '.rate_limits.five_hour.used_percentage')")
[ -n "$five" ] && add "$(limit_segment 5h "$five" "$(get '.rate_limits.five_hour.resets_at')")"

week=$(round_pct "$(get '.rate_limits.seven_day.used_percentage')")
[ -n "$week" ] && add "$(limit_segment 7d "$week" "$(get '.rate_limits.seven_day.resets_at')")"

printf '%s' "$out"
