#!/bin/bash

ERR_TOO_FEW_SOURCES=$((0x01))
ERR_TOO_MANY_SOURCES=$((0x02))

__get_script_dir()
{
    local SOURCE_PATH="${BASH_SOURCE[0]}"
    local SYMLINK_DIR
    local SCRIPT_DIR

    while [ -L "$SOURCE_PATH" ]
    do
        SYMLINK_DIR="$(cd -P "$(dirname "$SOURCE_PATH")" &>/dev/null && pwd)"
        SOURCE_PATH="$(readlink "$SOURCE_PATH")"

        if [[ $SOURCE_PATH != /* ]]; then
            SOURCE_PATH=$SYMLINK_DIR/$SOURCE_PATH
        fi
    done

    SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE_PATH")" &>/dev/null && pwd)"
    echo "$SCRIPT_DIR"
}

__get_sources_path()
{
    echo "$(__get_script_dir)/shell-beats.sources"
}

print_help()
{
    printf "%s\n" "Play music in the background"
    printf "  %s\n" "Usage: ./shell-beats.sh [options]"
    printf "%s\n" "[options]"
    printf "  %s\n" "list               list the available streams"
    printf "  %s\n" "play <stream>      play the <stream> by name"
}

_parse_sources()
{
    grep -Ev '^(\s*#.*)?$' "$(__get_sources_path)"
}

_parse_source_name()
{
    echo "${1% *}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_parse_source_url()
{
    echo "${1##* }" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

list()
{
    _parse_sources | while read line
    do
        local NAME="$(_parse_source_name "$line")"
        local URL="$(_parse_source_url "$line")"

        printf "\033[32m%s\033[m\t(%s)\n" "$NAME" "$URL"
    done | column -t -s $'\t'
}

_select_source()
{
    local MATCHES="$(_parse_sources | grep -i "$*")"
    local COUNT=$(echo "$MATCHES" | sed '/^$/d' | wc -l)

    if [ "$COUNT" -lt 1 ]; then
        echo "No sources found." >&2
        return $ERR_TOO_FEW_SOURCES
    fi

    if [ "$COUNT" -eq 1 ]; then
        echo "$MATCHES"
        return 0
    fi

    echo "Too many sources found. (TBD source selection)" >&2
    return $ERR_TOO_MANY_SOURCES
}

play()
{
    local SOURCE; SOURCE="$(_select_source "$*")" || return $?
    local NAME="$(_parse_source_name "$SOURCE")"
    local URL="$(_parse_source_url "$SOURCE")"

    printf "Now Playing: \033[32m%s\033[m\n -> (%s)\n" "$NAME" "$URL"
    mpv --no-video "$URL" &>/dev/null
}

_on_sigint()
{
    echo
    exit 0
}
trap _on_sigint SIGINT

case $1 in
    list)
        list
        ;;
    play)
        play "${@:2}"
        ;;
    *)
        print_help
        ;;
esac
