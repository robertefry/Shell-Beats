#!/bin/sh

ERR_SOURCES_TOO_FEW=$((0x01))
ERR_SOURCES_TOO_MANY=$((0x02))

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
    printf '%s\n' "${1% *}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_parse_source_url()
{
    printf '%s\n' "${1##* }" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

list()
{
    _parse_sources | while IFS= read -r _line
    do
        _NAME="$(_parse_source_name "$_line")"
        _URL="$(_parse_source_url "$_line")"

        printf "\033[32m%s\033[m\t\033[2;3;37m(%s)\033[m\n" "$_NAME" "$_URL"
    done | column -t -s "$(printf '\t')"
}

_select_source()
{
    _SOURCES="$(_parse_sources | grep -i "$*")"
    _SOURCE_COUNT="$(printf '%s\n' "$_SOURCES" | sed '/^$/d' | wc -l)"

    if [ "$_SOURCE_COUNT" -lt 1 ]; then
        printf '%s\n' "No sources found." >&2
        return $ERR_SOURCES_TOO_FEW
    fi

    if [ "$_SOURCE_COUNT" -eq 1 ]; then
        printf '%s\n' "$_SOURCES"
        return 0
    fi

    printf '%s\n' "Too many sources found. (TBD source selection)" >&2
    return $ERR_SOURCES_TOO_MANY
}

play()
{
    _SOURCE="$(_select_source "$*")" || return $?
    _NAME="$(_parse_source_name "$_SOURCE")"
    _URL="$(_parse_source_url "$_SOURCE")"

    printf "Now Playing: \033[32m%s\033[m\n -> (%s)\n" "$_NAME" "$_URL"
    mpv --no-video "$_URL" >/dev/null 2>&1
}

_clean_exit()
{
    printf '\n'; exit 0
}
trap _clean_exit INT TERM

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
