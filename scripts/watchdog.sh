#!/system/bin/sh

watchdog_loop() {
    [ "${WATCHDOG:-1}" = "1" ] || return 0

    last_sig=""
    interval="${WATCHDOG_INTERVAL:-2}"
    reapply_interval="${WATCHDOG_REAPPLY_INTERVAL:-15}"
    tick=0

    while true; do
        pids="$(find_game_pids 2>/dev/null)"
        if [ -z "$pids" ]; then
            last_sig=""
            tick=0
            sleep 10
            continue
        fi

        sig="$(game_signature 2>/dev/null || echo "")"
        if [ "$sig" != "$last_sig" ]; then
            log_info "Free Fire detected"
            last_sig="$sig"
            for pid in $pids; do
                [ -d "/proc/$pid" ] || continue
                apply_affinity "$pid" || true
            done
            tick=0
        fi

        if [ "${WATCH_SWAP:-1}" = "1" ] && memory_needs_apply; then
            disable_swap || true
            disable_zram || true
        fi

        if cpu_needs_apply; then
            apply_cpu || true
        fi
        if gpu_needs_apply; then
            apply_gpu || true
        fi
        if kgsl_needs_apply; then
            apply_kgsl || true
        fi

        tick=$((tick+1))
        if [ "$tick" -ge "$reapply_interval" ]; then
            for pid in $pids; do
                [ -d "/proc/$pid" ] || continue
                apply_affinity "$pid" || true
            done
            tick=0
        fi

        sleep "$interval"
    done
}
