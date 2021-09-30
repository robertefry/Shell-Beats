#!/bin/sh

__help()
{
    printf "%s\n" "Play lofi music in the background"
    printf "  %s\n" "Usage: ./shell-beats.sh [options]"
    printf "%s\n" "[options]"
    printf "  %s\n" "list               list the available streams"
    printf "  %s\n" "play <stream>      play the <stream> by name"
}

__list()
{
    printf "\033[32m%s\033[m (%s)\n" $(grep -Ev '^(\s*#.*)?$' shell-beats.sources)
}

__play()
{
    printf "Now Playing: %s ☕️🎶...\n -> (%s)\n" $(grep $1 shell-beats.sources)
    mpv $(grep $1 shell-beats.sources | cut -d' ' -f2)
}

case $1 in
    list)
        __list
        ;;
    play)
        __play $2
        ;;
    *)
        __help
        ;;
esac
