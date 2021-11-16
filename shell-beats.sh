#!/bin/sh

__help()
{
    printf "%s\n" "Play lofi music in the background"
    printf "  %s\n" "Usage: ./shell-beats.sh [options]"
    printf "%s\n" "[options]"
    printf "  %s\n" "list               list the available streams"
    printf "  %s\n" "play <stream>      play the <stream> by name"
}

__parse()
{
    grep -Ev '^(\s*\#.*)?$' shell-beats.sources
}

__list()
{
    __parse | while read line
    do
        printf "\033[32m%s\033[m (%s)\n" "${line% *}" "${line##* }"
    done
}

__play()
{
    line=$(__parse | grep "$*")
    printf "Now Playing: %s ☕️🎶...\n -> (%s)\n" "${line% *}" "${line##* }"
    mpv --no-video "${line##* }"
}

case $1 in
    list)
        __list
        ;;
    play)
        __play "${@:2}"
        ;;
    *)
        __help
        ;;
esac
