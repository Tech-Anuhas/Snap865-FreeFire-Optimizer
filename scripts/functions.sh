#!/system/bin/sh

SUCCESS=0
WARNING=1
FAILED=2
SKIPPED=3

file_exists() { [ -e "$1" ]; }
file_writable() { [ -w "$1" ]; }

safe_read() {
    file_exists "$1" || return $SKIPPED
    cat "$1" 2>/dev/null
}

safe_write() {
    file="$1"
    value="$2"

    file_exists "$file" || return $SKIPPED
    file_writable "$file" || return $FAILED

    cur="$(cat "$file" 2>/dev/null)"
    [ "$cur" = "$value" ] && return $SUCCESS

    echo "$value" > "$file" 2>/dev/null || return $FAILED
    cur="$(cat "$file" 2>/dev/null)"
    [ "$cur" = "$value" ] && return $SUCCESS
    return $FAILED
}

retry_write() {
    tries="$1"
    file="$2"
    value="$3"
    i=1
    rc=1
    while [ "$i" -le "$tries" ]; do
        safe_write "$file" "$value"
        rc=$?
        [ "$rc" -eq 0 ] && return 0
        [ "$rc" -eq $SKIPPED ] && return $SKIPPED
        sleep 0.1
        i=$((i+1))
    done
    return "$rc"
}

safe_taskset() {
    mask="$1"
    tid="$2"
    taskset -p "$mask" "$tid" >/dev/null 2>&1
    return $?
}

safe_renice() {
    nicev="$1"
    tid="$2"
    renice -n "$nicev" -p "$tid" >/dev/null 2>&1
    return $?
}

safe_swapoff() {
    dev="$1"
    [ -n "$dev" ] || return $SKIPPED
    swapoff "$dev" >/dev/null 2>&1
    return $?
}

safe_proc_write() {
    file="$1"
    value="$2"
    [ -e "$file" ] || return $SKIPPED
    echo "$value" > "$file" 2>/dev/null
    return $?
}
