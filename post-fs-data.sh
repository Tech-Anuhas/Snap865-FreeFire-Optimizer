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

[ -f "$MODDIR/config/config.conf" ] && . "$MODDIR/config/config.conf"

log_init
set_log_level_from_conf "${LOG_LEVEL:-INFO}"
log_info "post-fs-data started"

[ "${SAFE_MODE:-0}" = "1" ] && { warn "SAFE_MODE enabled; boot tweaks skipped"; exit 0; }

if verify_model && verify_platform && [ "${EARLY_APPLY:-0}" = "1" ]; then
    apply_cpu || check_rc $? "early cpu apply"
    apply_gpu || check_rc $? "early gpu apply"
    apply_kgsl || check_rc $? "early kgsl apply"
    disable_swap || check_rc $? "early swap disable"
    disable_zram || check_rc $? "early zram disable"
else
    log_info "early apply skipped"
fi

exit 0
