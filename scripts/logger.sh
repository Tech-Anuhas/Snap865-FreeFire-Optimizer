#!/system/bin/sh

LOGDIR="${MODDIR:-/data/local/tmp}/logs"
LOGFILE="$LOGDIR/module.log"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

log_init() {
    mkdir -p "$LOGDIR" 2>/dev/null
    : > "$LOGFILE" 2>/dev/null || true
}

log_rotate() {
    [ -f "$LOGFILE" ] || return 0
    size=$(wc -c < "$LOGFILE" 2>/dev/null)
    [ -n "$size" ] || return 0
    [ "$size" -lt 1048576 ] && return 0
    mv "$LOGFILE" "$LOGFILE.1" 2>/dev/null || true
    : > "$LOGFILE" 2>/dev/null || true
}

_log() {
    lvl="$1"
    shift
    case "$LOG_LEVEL" in
        DEBUG) ;;
        INFO) [ "$lvl" = "DEBUG" ] && return 0 ;;
        WARN) [ "$lvl" = "DEBUG" ] && return 0; [ "$lvl" = "INFO" ] && return 0 ;;
        ERROR) [ "$lvl" != "ERROR" ] && return 0 ;;
    esac
    log_rotate
    printf "[%s] [%s] %s\n" "$(date '+%F %T')" "$lvl" "$*" >> "$LOGFILE" 2>/dev/null
}

log_info() { _log INFO "$*"; }
log_warn() { _log WARN "$*"; }
log_error() { _log ERROR "$*"; }

set_log_level_from_conf() {
    case "$(echo "${1:-INFO}" | tr '[:lower:]' '[:upper:]')" in
        DEBUG|INFO|WARN|ERROR) LOG_LEVEL="$(echo "${1}" | tr '[:lower:]' '[:upper:]')" ;;
        *) LOG_LEVEL=INFO ;;
    esac
}
