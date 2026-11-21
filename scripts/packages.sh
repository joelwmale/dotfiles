#!/usr/bin/env bash
# Homebrew formulae, casks and Mac App Store apps, chosen interactively.
# The lists live in config/packages/*.list as: name|group|default|description

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

PKG_DIR="$ROOT/config/packages"

# select_packages <list file> <title> <kind>  - sets PKG_SELECTED to the chosen names.
select_packages() {
    local file="$1" title="$2" kind="$3"
    local groups="" name group def desc g n names d entries=() items=()

    while IFS='|' read -r name group def desc; do
        case "$name" in ''|\#*) continue ;; esac
        case " $groups " in *" $group "*) ;; *) groups="$groups $group" ;; esac
    done < "$file"

    for g in $groups; do
        n=0; names=""; d=0
        while IFS='|' read -r name group def desc; do
            case "$name" in ''|\#*) continue ;; esac
            [ "$group" = "$g" ] || continue
            n=$((n + 1))
            if [ "$kind" = mas ]; then
                names="$names, ${desc%% (*}"
            else
                names="$names, ${name##*/}"
            fi
            d=$def
        done < "$file"
        entries+=("$g|$g ($n): ${names#, }|$d")
    done

    menu "$title (groups)" "${entries[@]}"
    local chosen=" $MENU_RESULT "

    while IFS='|' read -r name group def desc; do
        case "$name" in ''|\#*) continue ;; esac
        case "$chosen" in
            *" $group "*)
                if [ "$kind" = mas ]; then
                    items+=("$name|$desc|1")
                else
                    items+=("$name|$name - $desc|1")
                fi
                ;;
        esac
    done < "$file"

    PKG_SELECTED=""
    if [ ${#items[@]} -eq 0 ]; then
        return 0
    fi

    if ask "Review $title one by one?" N; then
        menu "$title (items)" "${items[@]}"
        PKG_SELECTED="$MENU_RESULT"
    else
        local item
        for item in "${items[@]}"; do
            PKG_SELECTED="$PKG_SELECTED ${item%%|*}"
        done
        PKG_SELECTED="${PKG_SELECTED# }"
    fi
}

install_homebrew() {
    command -v brew >/dev/null 2>&1 && return 0
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    fi

    action "installing homebrew"
    if [ "$DRY_RUN" = 1 ]; then
        echo "  [dry-run] Homebrew install script"
        return 0
    fi
    NONINTERACTIVE=1 fetch_and_run https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh /bin/bash || {
        error "unable to install homebrew, aborting"
        exit 1
    }
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

bot 'Packages'
install_homebrew

if ask 'Run brew update && upgrade first?' N; then
    run brew update && run brew upgrade
fi

select_packages "$PKG_DIR/brew.list" "Command-line tools" brew
FORMULAE="$PKG_SELECTED"
for name in $FORMULAE; do
    brew_install "$name"
done

case " $FORMULAE " in
    *" mysql@8.4 "*)
        service_start mysql@8.4
        if ask 'Set the MySQL root password to "root" (local development only)?' N; then
            MYSQL_BIN="$(brew --prefix mysql@8.4)/bin"
            for _ in 1 2 3 4 5 6 7 8 9 10; do
                [ "$DRY_RUN" = 1 ] && break
                "$MYSQL_BIN/mysqladmin" -u root ping >/dev/null 2>&1 && break
                sleep 2
            done
            run "$MYSQL_BIN/mysql" -u root \
                -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'root';"
        fi
        ;;
esac
case " $FORMULAE " in
    *" redis "*) service_start redis ;;
esac

select_packages "$PKG_DIR/cask.list" "Applications" cask
for name in $PKG_SELECTED; do
    cask_install "$name"
done

if command -v mas >/dev/null 2>&1 || [ "$DRY_RUN" = 1 ]; then
    if ask 'Are you signed into the Mac App Store?' Y; then
        select_packages "$PKG_DIR/mas.list" "Mac App Store" mas
        while IFS='|' read -r id group def desc; do
            case "$id" in ''|\#*) continue ;; esac
            case " $PKG_SELECTED " in
                *" $id "*) mas_install "$id" "${desc%% (*}" ;;
            esac
        done < "$PKG_DIR/mas.list"
    fi
fi
