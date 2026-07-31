#!/system/bin/sh

gpu_needs_apply() {
    [ "${GPU_LOCK:-1}" = "1" ] || return 1
    base=/sys/class/kgsl/kgsl-3d0
    [ -d "$base" ] || return 1
    gov="${GPU_GOVERNOR:-performance}"
    freq="${GPU_FREQ:-845000000}"

    if [ -e "$base/devfreq/max_freq" ]; then
        [ "$(safe_read "$base/devfreq/governor" 2>/dev/null || echo "")" = "$gov" ] || return 0
        [ "$(safe_read "$base/devfreq/max_freq" 2>/dev/null || echo "")" = "$freq" ] || return 0
        [ "$(safe_read "$base/devfreq/min_freq" 2>/dev/null || echo "")" = "$freq" ] || return 0
        return 1
    fi

    if [ -e "$base/max_clock_mhz" ]; then
        [ "$(safe_read "$base/devfreq/governor" 2>/dev/null || echo "")" = "$gov" ] || return 0
        [ "$(safe_read "$base/max_clock_mhz" 2>/dev/null || echo "")" = "845" ] || return 0
        [ "$(safe_read "$base/min_clock_mhz" 2>/dev/null || echo "")" = "845" ] || return 0
        return 1
    fi

    if [ -e "$base/gpuclk" ]; then
        [ "$(safe_read "$base/devfreq/governor" 2>/dev/null || echo "")" = "$gov" ] || return 0
        [ "$(safe_read "$base/gpuclk" 2>/dev/null || echo "")" = "$freq" ] || return 0
        return 1
    fi

    return 1
}

apply_gpu() {
    [ "${GPU_LOCK:-1}" = "1" ] || return 0
    base=/sys/class/kgsl/kgsl-3d0
    [ -d "$base" ] || { log_warn "KGSL base missing"; return 0; }

    changed=0
    failed=0
    gov="${GPU_GOVERNOR:-performance}"
    freq="${GPU_FREQ:-845000000}"

    if [ -e "$base/devfreq/governor" ]; then
        cur="$(safe_read "$base/devfreq/governor" 2>/dev/null || echo "")"
        if [ "$cur" != "$gov" ]; then
            retry_write 3 "$base/devfreq/governor" "$gov"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    fi

    if [ -e "$base/devfreq/max_freq" ]; then
        cur="$(safe_read "$base/devfreq/max_freq" 2>/dev/null || echo "")"
        if [ "$cur" != "$freq" ]; then
            retry_write 3 "$base/devfreq/max_freq" "$freq"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
        cur="$(safe_read "$base/devfreq/min_freq" 2>/dev/null || echo "")"
        if [ "$cur" != "$freq" ]; then
            retry_write 3 "$base/devfreq/min_freq" "$freq"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    elif [ -e "$base/max_clock_mhz" ]; then
        cur="$(safe_read "$base/max_clock_mhz" 2>/dev/null || echo "")"
        if [ "$cur" != "845" ]; then
            retry_write 3 "$base/max_clock_mhz" 845
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
        cur="$(safe_read "$base/min_clock_mhz" 2>/dev/null || echo "")"
        if [ "$cur" != "845" ]; then
            retry_write 3 "$base/min_clock_mhz" 845
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    elif [ -e "$base/gpuclk" ]; then
        cur="$(safe_read "$base/gpuclk" 2>/dev/null || echo "")"
        if [ "$cur" != "$freq" ]; then
            retry_write 3 "$base/gpuclk" "$freq"
            rc=$?
            [ "$rc" -eq 0 ] && changed=1
            [ "$rc" -eq $FAILED ] && failed=1
        fi
    fi

    [ "$changed" -eq 1 ] && log_info "GPU engine applied"
    [ "$failed" -eq 1 ] && return 1
    return 0
}
