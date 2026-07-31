#!/system/bin/sh

cpu_needs_apply() {
    [ "${CPU_LOCK:-1}" = "1" ] || return 1
    gov="${CPU_GOVERNOR:-performance}"
    for p in /sys/devices/system/cpu/cpufreq/policy0 \
             /sys/devices/system/cpu/cpufreq/policy4 \
             /sys/devices/system/cpu/cpufreq/policy7
    do
        [ -d "$p" ] || continue
        max="$(safe_read "$p/cpuinfo_max_freq")" || continue
        [ "$(safe_read "$p/scaling_governor" 2>/dev/null || echo "")" = "$gov" ] || return 0
        [ "$(safe_read "$p/scaling_max_freq" 2>/dev/null || echo "")" = "$max" ] || return 0
        [ "$(safe_read "$p/scaling_min_freq" 2>/dev/null || echo "")" = "$max" ] || return 0
    done
    return 1
}

apply_cpu() {
    [ "${CPU_LOCK:-1}" = "1" ] || return 0
    gov="${CPU_GOVERNOR:-performance}"
    changed=0
    failed=0

    for p in /sys/devices/system/cpu/cpufreq/policy0 \
             /sys/devices/system/cpu/cpufreq/policy4 \
             /sys/devices/system/cpu/cpufreq/policy7
    do
        [ -d "$p" ] || continue
        max="$(safe_read "$p/cpuinfo_max_freq")" || continue

        curgov="$(safe_read "$p/scaling_governor" 2>/dev/null || echo "")"
        curmax="$(safe_read "$p/scaling_max_freq" 2>/dev/null || echo "")"
        curmin="$(safe_read "$p/scaling_min_freq" 2>/dev/null || echo "")"

        if [ "$curgov" != "$gov" ]; then
            retry_write 3 "$p/scaling_governor" "$gov"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
        if [ "$curmax" != "$max" ]; then
            retry_write 3 "$p/scaling_max_freq" "$max"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
        if [ "$curmin" != "$max" ]; then
            retry_write 3 "$p/scaling_min_freq" "$max"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    done

    [ "$changed" -eq 1 ] && log_info "CPU engine applied"
    [ "$failed" -eq 1 ] && return 1
    return 0
}
