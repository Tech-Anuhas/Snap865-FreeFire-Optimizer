#!/system/bin/sh

cgroup_write_pid() {
    group="$1"
    pid="$2"
    [ -e "$group/cgroup.procs" ] && { echo "$pid" > "$group/cgroup.procs" 2>/dev/null || true; return 0; }
    [ -e "$group/tasks" ] && { echo "$pid" > "$group/tasks" 2>/dev/null || true; return 0; }
    return 1
}

apply_uclamp_group() {
    [ "${UCLAMP:-1}" = "1" ] || return 0
    base=/dev/cpuctl/top-app
    [ -d "$base" ] || return 0

    if [ -e "$base/cpu.uclamp.min" ]; then
        tgtmin="${UCLAMP_MIN:-1024}"
        cur="$(safe_read "$base/cpu.uclamp.min" 2>/dev/null || echo "")"
        [ "$cur" = "$tgtmin" ] || retry_write 3 "$base/cpu.uclamp.min" "$tgtmin" || true
    fi
    if [ -e "$base/cpu.uclamp.max" ]; then
        tgtmax="${UCLAMP_MAX:-1024}"
        cur="$(safe_read "$base/cpu.uclamp.max" 2>/dev/null || echo "")"
        [ "$cur" = "$tgtmax" ] || retry_write 3 "$base/cpu.uclamp.max" "$tgtmax" || true
    fi
    if [ -e "$base/cpu.uclamp.latency_sensitive" ]; then
        cur="$(safe_read "$base/cpu.uclamp.latency_sensitive" 2>/dev/null || echo "")"
        [ "$cur" = "1" ] || retry_write 3 "$base/cpu.uclamp.latency_sensitive" 1 || true
    fi
}

apply_game_cgroups() {
    [ "${THREAD_AFFINITY:-1}" = "1" ] || return 0
    pid="$1"
    [ -n "$pid" ] || return 1

    cgroup_write_pid /dev/cpuset/top-app "$pid" || true
    cgroup_write_pid /dev/stune/top-app "$pid" || true
    cgroup_write_pid /dev/cpuctl/top-app "$pid" || true
    apply_uclamp_group
    return 0
}

apply_affinity() {
    [ "${THREAD_AFFINITY:-1}" = "1" ] || return 0
    pid="$1"
    [ -n "$pid" ] || return 1

    apply_game_cgroups "$pid"

    for t in /proc/"$pid"/task/*; do
        [ -e "$t/comm" ] || continue
        tid="$(basename "$t")"
        name="$(cat "$t"/comm 2>/dev/null)"

        case "$name" in
            UnityMain)
                safe_taskset 0x80 "$tid" || true
                [ "${THREAD_PRIORITY:-1}" = "1" ] && safe_renice -20 "$tid" || true
                ;;
            UnityGfxDeviceW*|UnityChoreograp*)
                safe_taskset 0xF0 "$tid" || true
                ;;
            Job.Worker*|Loading.AsyncRe*|CloudJob.Worker|pool-*-thread-*)
                safe_taskset 0x70 "$tid" || true
                ;;
            AudioTrack|FMOD*|AudioPortEventH|Audio*)
                safe_taskset 0x0F "$tid" || true
                ;;
            binder:*|Signal\ Catcher|Jit\ thread\ pool|HeapTaskDaemon|ReferenceQueueD|FinalizerDaemon|FinalizerWatchd|Profile\ Saver|DefaultDispatch*|OkHttp*|GoogleApiHandle*|MessengerIpcCli|Firebase*|ConnectivityThr*|WifiManagerThre*|Thread-*|pool-*|WM.task-*|queued-work-loo|ProcessStablePh|GmsDynamite|AssetGarbageCol|Loading.Preload|BatchDeleteObje|Timer-0|internal)
                safe_taskset 0x0F "$tid" || true
                ;;
            *)
                :
                ;;
        esac
    done

    log_info "Affinity applied to PID $pid"
    return 0
}
