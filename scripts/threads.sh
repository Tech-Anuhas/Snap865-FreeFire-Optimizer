#!/system/bin/sh

FREEFIRE_PKG="${FREEFIRE_PKG:-com.dts.freefireth}"
FREEFIRE_MAX_PKG="${FREEFIRE_MAX_PKG:-com.dts.freefiremax}"

find_game_pids() {
    pidof "$FREEFIRE_PKG" 2>/dev/null || pidof "$FREEFIRE_MAX_PKG" 2>/dev/null
}

find_game_pid() {
    set -- $(find_game_pids 2>/dev/null)
    [ -n "$1" ] && echo "$1"
}

list_threads() {
    pid="$1"
    [ -n "$pid" ] || return 1
    for t in /proc/"$pid"/task/*; do
        [ -e "$t/comm" ] || continue
        printf "%s:%s\n" "$(basename "$t")" "$(cat "$t"/comm 2>/dev/null)"
    done
}

thread_signature() {
    pid="$1"
    [ -n "$pid" ] || return 1
    {
        for t in /proc/"$pid"/task/*; do
            [ -e "$t/comm" ] || continue
            printf "%s=%s\n" "$(basename "$t")" "$(cat "$t"/comm 2>/dev/null)"
        done
    } | sort | cksum | cut -d' ' -f1
}

game_signature() {
    pids="$(find_game_pids 2>/dev/null)"
    [ -n "$pids" ] || return 1
    {
        for pid in $pids; do
            [ -d "/proc/$pid/task" ] || continue
            for t in /proc/"$pid"/task/*; do
                [ -e "$t/comm" ] || continue
                printf "%s:%s=%s\n" "$pid" "$(basename "$t")" "$(cat "$t"/comm 2>/dev/null)"
            done
        done
    } | sort | cksum | cut -d' ' -f1
}
