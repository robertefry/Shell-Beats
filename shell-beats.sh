#!/bin/bash

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

        printf "\033[32m%s\033[m (%s)\n" "$NAME" "$URL"
    done
}

play()
{
    local LINE="$(_parse_sources | grep "$*")"
    local NAME="$(_parse_source_name "$LINE")"
    local URL="$(_parse_source_url "$LINE")"

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
        help
        ;;
esac
