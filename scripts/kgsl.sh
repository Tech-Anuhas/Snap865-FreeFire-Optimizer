#!/system/bin/sh

kgsl_needs_apply() {
    [ "${KGSL_PERFORMANCE:-1}" = "1" ] || return 1
    base=/sys/class/kgsl/kgsl-3d0
    [ -d "$base" ] || return 1

    for f in force_clk_on force_bus_on force_rail_on force_no_nap; do
        [ -e "$base/$f" ] || continue
        [ "$(safe_read "$base/$f" 2>/dev/null || echo "")" = "1" ] || return 0
    done

    if [ -e "$base/wake_nice" ]; then
        [ "$(safe_read "$base/wake_nice" 2>/dev/null || echo "")" = "0" ] || return 0
    fi

    return 1
}

apply_kgsl() {
    [ "${KGSL_PERFORMANCE:-1}" = "1" ] || return 0
    base=/sys/class/kgsl/kgsl-3d0
    [ -d "$base" ] || return 0

    changed=0
    failed=0

    for f in force_clk_on force_bus_on force_rail_on force_no_nap
    do
        [ -e "$base/$f" ] || continue
        cur="$(safe_read "$base/$f" 2>/dev/null || echo "")"
        if [ "$cur" != "1" ]; then
            retry_write 3 "$base/$f" 1
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    done

    if [ -e "$base/wake_nice" ]; then
        cur="$(safe_read "$base/wake_nice" 2>/dev/null || echo "")"
        if [ "$cur" != "0" ]; then
            retry_write 3 "$base/wake_nice" 0
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    fi

    [ "$changed" -eq 1 ] && log_info "KGSL performance flags applied"
    [ "$failed" -eq 1 ] && return 1
    return 0
}
