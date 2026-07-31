#!/system/bin/sh

die() {
    log_error "$*"
    return 1
}

warn() {
    log_warn "$*"
    return 0
}

check_rc() {
    rc="$1"
    msg="$2"
    [ "$rc" -eq 0 ] && return 0
    log_warn "$msg (rc=$rc)"
    return "$rc"
}
