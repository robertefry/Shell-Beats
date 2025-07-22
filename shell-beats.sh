#!/bin/sh

# TODO: allow regex search terms
# TODO: show mpv stderr with `-v` option
# TODO: show mpv stdout with `-vv` option

ERR_SOURCE_NOT_FOUND=$((0x01))
ERR_SOURCES_TOO_FEW=$((0x02))
ERR_SOURCES_TOO_MANY=$((0x03))
ERR_FAILED_TO_PLAY=$((0x10))

MPV_PID=""

__get_script_dir()
{
    _SOURCE_PATH="$0"

    while [ -L "$_SOURCE_PATH" ]
    do
        _SYMLINK_DIR="$(cd -P "$(dirname "$_SOURCE_PATH")" >/dev/null 2>&1 && pwd)"
        _SYMLINK_TARGET="$(readlink "$_SOURCE_PATH")"

        case "$_SYMLINK_TARGET" in
            /*) _SOURCE_PATH="$_SYMLINK_TARGET" ;;
            *)  _SOURCE_PATH="$_SYMLINK_DIR/$_SYMLINK_TARGET" ;;
        esac
    done

    _SCRIPT_DIR="$(cd -P "$(dirname "$_SOURCE_PATH")" >/dev/null 2>&1 && pwd)"
    printf '%s\n' "$_SCRIPT_DIR"
}

__get_sources_path()
{
    printf '%s\n' "$(__get_script_dir)/shell-beats.sources"
}

print_help()
{
    printf "%s\n" "Play music in the background"
    printf "%s\n" "  Usage: $(basename "$0") [options]"
    printf "%s\n" "[options]"
    printf "%s\n" "  list               list the available streams"
    printf "%s\n" "  play <stream>      play the <stream> by name"
}

_parse_sources()
{
    grep -Ev '^([[:space:]]*#.*)?$' "$(__get_sources_path)"
}

_parse_source_name()
{
    printf '%s\n' "${1%%=*}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_parse_source_url()
{
    printf '%s\n' "${1#*=}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_format_source()
{
    _SOURCE="$1"
    _NAME="$(_parse_source_name "$_SOURCE")"
    _URL="$(_parse_source_url "$_SOURCE")"

    printf "\033[32m%s\033[m\t\033[2;3;37m(%s)\033[m\n" "$_NAME" "$_URL"
}

list()
{
    _parse_sources | while IFS= read -r _line
    do
        printf "%s\n" "$(_format_source "$_line")"
    done | column -t -s "$(printf '\t')"
}

_select_source_into()
{
    _SOURCE_VAR="$1"
    shift

    _SOURCES="$(_parse_sources | grep -i "$*")"
    _SOURCE_COUNT="$(printf '%s\n' "$_SOURCES" | sed '/^$/d' | wc -l)"

    if [ "$_SOURCE_COUNT" -lt 1 ]; then
        printf '%s\n' "No sources found." >&2
        return "$ERR_SOURCE_NOT_FOUND"
    fi

    if [ "$_SOURCE_COUNT" -eq 1 ]; then
        eval "$_SOURCE_VAR=\$(printf '%s\n' \"\$_SOURCES\")"
        return 0
    fi

    printf '%s\n' "Multiple sources found."
    _SOURCE_INDEX=1

    while IFS= read -r _line
    do
        printf '  %d) %s\n' "$_SOURCE_INDEX" "$(_format_source "$_line")"
        eval "_SOURCE_$((_SOURCE_INDEX))=\"\$_line\""
        _SOURCE_INDEX=$((_SOURCE_INDEX + 1))
    done <<EOF
        $_SOURCES
EOF

    while :; do
        printf 'Please select a source [1-%d]: ' "$((_SOURCE_INDEX - 1))"
        IFS= read -r _SOURCE_SELECTION

        case $_SOURCE_SELECTION in
            ''|*[!0-9]*)
                ;;
            *)
                if  [ "$_SOURCE_SELECTION" -ge 1 ] &&
                    [ "$_SOURCE_SELECTION" -lt "$_SOURCE_INDEX" ]
                then
                    eval "$_SOURCE_VAR=\$(printf '%s\n' \"\$_SOURCE_$_SOURCE_SELECTION\")"
                    return 0
                fi
                ;;
        esac

        printf '%s\n' "Invalid selection: \"$_SOURCE_SELECTION\"" >&2
    done
}

play()
{
    _select_source_into "_SOURCE" "$*" || return "$?"

    _NAME="$(_parse_source_name "$_SOURCE")"
    _URL="$(_parse_source_url "$_SOURCE")"

    printf "Now Playing: \033[32m%s\033[m\n -> (%s)\n" "$_NAME" "$_URL"

    mpv --no-video --no-sub --msg-level=all=no "$_URL" &
    MPV_PID="$!"
    wait "$MPV_PID"; MPV_EXIT_CODE="$?"; MPV_PID=""

    if [ "$MPV_EXIT_CODE" -ne 0 ]
    then
        printf 'Error: Failed to play URL %s\n' "$_URL" >&2
        return "$ERR_FAILED_TO_PLAY"
    fi
}

__exit_dirty()
{
    test -n "$MPV_PID" && kill "$MPV_PID"
}
trap __exit_dirty EXIT TERM

__exit_clean()
{
    __exit_dirty
    exit 0
}
trap __exit_clean INT

case $1 in
    list)
        list
        ;;
    play)
        shift
        play "$@"
        ;;
    *)
        print_help
        ;;
esac
