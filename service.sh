#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/scripts/functions.sh"
. "$MODDIR/scripts/logger.sh"
. "$MODDIR/scripts/error.sh"
. "$MODDIR/scripts/verify.sh"
. "$MODDIR/scripts/cpu.sh"
. "$MODDIR/scripts/gpu.sh"
. "$MODDIR/scripts/kgsl.sh"
. "$MODDIR/scripts/memory.sh"
. "$MODDIR/scripts/threads.sh"
. "$MODDIR/scripts/scheduler.sh"
. "$MODDIR/scripts/watchdog.sh"

[ -f "$MODDIR/config/config.conf" ] && . "$MODDIR/config/config.conf"

boot_wait() {
    timeout="${BOOT_WAIT_TIMEOUT:-300}"
    count=0
    while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$count" -lt "$timeout" ]; do
        sleep 2
        count=$((count+2))
    done

    if [ "$(getprop sys.boot_completed)" != "1" ]; then
        log_warn "boot_completed timeout reached"
        return 1
    fi

    count=0
    while [ ! -d /sdcard/Android ] && [ "$count" -lt "$timeout" ]; do
        sleep 1
        count=$((count+1))
    done

    if [ ! -d /sdcard/Android ]; then
        log_warn "sdcard mount timeout reached"
    fi
    return 0
}

main() {
    log_init
    set_log_level_from_conf "${LOG_LEVEL:-INFO}"
    log_info "service started"

    [ "${SAFE_MODE:-0}" = "1" ] && { warn "SAFE_MODE enabled; runtime tweaks skipped"; exit 0; }

    if ! verify_device; then
        log_error "device verification failed; module disabled"
        exit 0
    fi

    boot_wait || { log_warn "boot wait failed; exiting safely"; exit 0; }

    log_info "Android boot completed"

    apply_cpu || check_rc $? "cpu engine"
    apply_gpu || check_rc $? "gpu engine"
    apply_kgsl || check_rc $? "kgsl engine"
    disable_swap || check_rc $? "swap engine"
    disable_zram || check_rc $? "zram engine"

    log_info "boot engines initialized"
    watchdog_loop
}

main
