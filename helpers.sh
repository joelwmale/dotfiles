#!/usr/bin/env bash
# Shared helpers. Targets bash 3.2 (the macOS default): no associative arrays, no ${var,,}.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
export ROOT DRY_RUN ASSUME_YES

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"

ok()      { echo -e "$COL_GREEN[ok]$COL_RESET $1"; }
bot()     { echo -e "\n$COL_GREEN[._.]$COL_RESET - $1"; }
running() { echo -e "$COL_YELLOW ⇒ $COL_RESET$1"; }
action()  { echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..."; }
warn()    { echo -e "$COL_YELLOW[warning]$COL_RESET $1"; }
error()   { echo -e "$COL_RED[error]$COL_RESET $1"; }
say()     { echo "$1"; }

# Run a command, or only print it under --dry-run.
run() {
    if [ "$DRY_RUN" = 1 ]; then
        echo "  [dry-run] $*"
        return 0
    fi
    "$@"
}

# ask "question" [Y|N]  - returns 0 for yes. --yes takes the default (yes when none).
ask() {
    local prompt default reply
    case "${2:-}" in
        Y) prompt="Y/n"; default=Y ;;
        N) prompt="y/N"; default=N ;;
        *) prompt="y/n"; default= ;;
    esac

    if [ "$ASSUME_YES" = 1 ]; then
        [ "$default" != N ]
        return
    fi

    while true; do
        echo -n "$1 [$prompt] "
        if ! read -r reply </dev/tty; then
            [ "$default" = Y ]
            return
        fi
        [ -z "$reply" ] && reply=$default
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

# prompt "question" [default]  - sets ANSWER. --yes takes the default.
prompt() {
    ANSWER="${2:-}"
    [ "$ASSUME_YES" = 1 ] && return 0
    local reply
    echo -n "$1${2:+ [$2]}: "
    read -r reply </dev/tty || return 0
    [ -n "$reply" ] && ANSWER="$reply"
    return 0
}

# menu "Title" "key|label|1" ...  - checklist. Sets MENU_RESULT to the chosen keys.
# Up/down (or k/j) move, space toggles, a = all, n = none, enter confirms. --yes keeps the defaults.
menu() {
    local title="$1"; shift
    local keys=() labels=() states=() entry rest i n cur=0 key seq

    for entry in "$@"; do
        keys+=("${entry%%|*}")
        rest="${entry#*|}"
        labels+=("${rest%|*}")
        states+=("${rest##*|}")
    done
    n=${#keys[@]}

    if [ "$ASSUME_YES" != 1 ] && [ "$n" -gt 0 ]; then
        _menu_draw() {
            local mark pointer
            for ((i = 0; i < n; i++)); do
                mark=" "; pointer=" "
                [ "${states[$i]}" = 1 ] && mark="x"
                [ "$i" = "$cur" ] && pointer=">"
                printf '\033[2K'
                if [ "$i" = "$cur" ]; then
                    printf '  %b%s [%s] %s%b\n' "$COL_GREEN" "$pointer" "$mark" "${labels[$i]}" "$COL_RESET"
                else
                    printf '  %s [%s] %s\n' "$pointer" "$mark" "${labels[$i]}"
                fi
            done
            printf '\033[2K  up/down move, space toggles, a all, n none, enter continues\n'
        }

        echo -e "\n$COL_GREEN$title$COL_RESET"
        printf '\033[?25l'
        trap 'printf "\033[?25h"; exit 130' INT
        _menu_draw
        while true; do
            IFS= read -rsn1 key </dev/tty || break
            case "$key" in
                '') break ;;
                ' ') if [ "${states[$cur]}" = 1 ]; then states[$cur]=0; else states[$cur]=1; fi ;;
                a|A) for ((i = 0; i < n; i++)); do states[$i]=1; done ;;
                n|N) for ((i = 0; i < n; i++)); do states[$i]=0; done ;;
                k) cur=$(( (cur + n - 1) % n )) ;;
                j) cur=$(( (cur + 1) % n )) ;;
                $'\033')
                    IFS= read -rsn2 seq </dev/tty
                    case "$seq" in
                        '[A') cur=$(( (cur + n - 1) % n )) ;;
                        '[B') cur=$(( (cur + 1) % n )) ;;
                    esac
                    ;;
                *) continue ;;
            esac
            printf '\033[%dA' $((n + 1))
            _menu_draw
        done
        printf '\033[?25h'
        trap - INT
    fi

    MENU_RESULT=""
    for ((i = 0; i < n; i++)); do
        [ "${states[$i]}" = 1 ] && MENU_RESULT="$MENU_RESULT ${keys[$i]}"
    done
    MENU_RESULT="${MENU_RESULT# }"
}

# link <source> <destination>  - symlink, moving anything already there to a backup folder.
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
link() {
    local src="$1" dest="$2"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return 0
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        run mkdir -p "$BACKUP_DIR"
        run mv "$dest" "$BACKUP_DIR/$(basename "$dest")"
        warn "moved existing $dest to $BACKUP_DIR"
    fi

    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
}

# fetch_and_run <url> <shell> [args]  - download first so a failed curl is an error, not an empty script.
fetch_and_run() {
    local url="$1" shell="$2" tmp
    shift 2
    tmp=$(mktemp) || return 1
    if ! curl -fsSL "$url" -o "$tmp"; then
        rm -f "$tmp"
        error "download failed: $url"
        return 1
    fi
    "$shell" "$tmp" "$@"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

# Run a command quietly, showing its last lines only when it fails.
quiet() {
    local log
    if [ "$DRY_RUN" = 1 ]; then
        echo "  [dry-run] $*"
        return 0
    fi
    log=$("$@" 2>&1 </dev/null) && return 0
    echo "$log" | tail -n 5
    return 1
}

brew_install() {
    action "brew install $1"
    if brew list --formula "${1##*/}" >/dev/null 2>&1; then
        ok "already installed"
        return 0
    fi
    quiet brew install "$1" && ok || error "failed to install $1, skipping"
}

cask_install() {
    action "brew install --cask $1"
    if brew list --cask "$1" >/dev/null 2>&1; then
        ok "already installed"
        return 0
    fi
    quiet brew install --cask "$1" && ok || error "failed to install $1, skipping"
}

mas_install() {
    action "mas install $1 ($2)"
    quiet mas install "$1" && ok || error "failed to install $2, skipping"
}

service_start() {
    action "brew services start $1"
    quiet brew services start "$1" && ok || error "failed to start $1, skipping"
}

composer_global() {
    action "composer global require $1"
    quiet composer global require "$1" && ok || error "failed to install $1 globally, skipping"
}
