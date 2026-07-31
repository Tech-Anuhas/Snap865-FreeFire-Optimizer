#!/system/bin/sh

swap_active() {
    [ -r /proc/swaps ] || return 1
    while read -r filename type size used priority; do
        [ "$filename" = "Filename" ] && continue
        [ -n "$filename" ] && return 0
    done < /proc/swaps
    return 1
}

zram_active() {
    for z in /sys/block/zram*; do
        [ -d "$z" ] || continue
        d="$(safe_read "$z/disksize" 2>/dev/null || echo "")"
        [ "$d" != "0" ] && return 0
    done
    return 1
}

memory_needs_apply() {
    [ "${WATCH_SWAP:-1}" = "1" ] || return 1
    [ "${DISABLE_SWAP:-1}" = "1" ] || return 1
    swap_active && return 0
    zram_active && return 0
    [ -e /proc/sys/vm/swappiness ] && [ "$(safe_read /proc/sys/vm/swappiness 2>/dev/null || echo "")" != "${SWAPPINESS:-0}" ] && return 0
    return 1
}

disable_swap() {
    [ "${DISABLE_SWAP:-1}" = "1" ] || return 0
    [ -r /proc/swaps ] || return 0

    changed=0
    failed=0

    while read -r filename type size used priority; do
        [ "$filename" = "Filename" ] && continue
        [ -z "$filename" ] && continue
        if [ -e "$filename" ]; then
            safe_swapoff "$filename"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    done < /proc/swaps

    if [ -e /proc/sys/vm/swappiness ]; then
        cur="$(safe_read /proc/sys/vm/swappiness 2>/dev/null || echo "")"
        tgt="${SWAPPINESS:-0}"
        if [ "$cur" != "$tgt" ]; then
            retry_write 3 /proc/sys/vm/swappiness "$tgt"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    fi

    [ "$changed" -eq 1 ] && log_info "Swap disabled"
    [ "$failed" -eq 1 ] && return 1
    return 0
}

disable_zram() {
    [ "${DISABLE_ZRAM:-1}" = "1" ] || return 0

    changed=0
    failed=0

    for z in /sys/block/zram*; do
        [ -d "$z" ] || continue
        dev="/dev/block/$(basename "$z")"

        if [ -e "$dev" ]; then
            safe_swapoff "$dev" >/dev/null 2>&1 || true
        fi

        if [ -w "$z/reset" ]; then
            d="$(safe_read "$z/disksize" 2>/dev/null || echo "")"
            if [ "$d" != "0" ]; then
                safe_proc_write "$z/reset" 1 >/dev/null 2>&1
                rc=$?
                [ "$rc" -eq 0 ] && changed=1
                [ "$rc" -eq $FAILED ] && failed=1
            fi
        fi

        if [ -w "$z/disksize" ]; then
            d="$(safe_read "$z/disksize" 2>/dev/null || echo "")"
            if [ "$d" != "0" ]; then
                safe_proc_write "$z/disksize" 0 >/dev/null 2>&1
                rc=$?
                [ "$rc" -eq 0 ] && changed=1
                [ "$rc" -eq $FAILED ] && failed=1
            fi
        fi
    done

    [ "$changed" -eq 1 ] && log_info "ZRAM disabled"
    [ "$failed" -eq 1 ] && return 1
    return 0
}
