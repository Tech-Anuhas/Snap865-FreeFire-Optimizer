#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/scripts/functions.sh"
. "$MODDIR/scripts/threads.sh"

diagnose() {
    echo "=== Snap865 Extreme ==="
    echo "Model: $(getprop ro.product.model)"
    echo "Platform: $(getprop ro.board.platform)"
    echo "ABI: $(getprop ro.product.cpu.abi)"
    echo

    echo "CPU policies:"
    for p in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$p" ] || continue
        echo "  $(basename "$p") gov=$(cat "$p/scaling_governor" 2>/dev/null) max=$(cat "$p/scaling_max_freq" 2>/dev/null) min=$(cat "$p/scaling_min_freq" 2>/dev/null)"
    done
    echo

    echo "GPU:"
    base=/sys/class/kgsl/kgsl-3d0
    if [ -d "$base" ]; then
        echo "  gov=$(cat "$base/devfreq/governor" 2>/dev/null)"
        echo "  max=$(cat "$base/devfreq/max_freq" 2>/dev/null)"
        echo "  min=$(cat "$base/devfreq/min_freq" 2>/dev/null)"
        echo "  pwrlevel=$(cat "$base/default_pwrlevel" 2>/dev/null)"
        echo "  force_clk_on=$(cat "$base/force_clk_on" 2>/dev/null)"
        echo "  force_bus_on=$(cat "$base/force_bus_on" 2>/dev/null)"
        echo "  force_rail_on=$(cat "$base/force_rail_on" 2>/dev/null)"
        echo "  force_no_nap=$(cat "$base/force_no_nap" 2>/dev/null)"
    fi
    echo

    echo "cpuset top-app:"
    cat /dev/cpuset/top-app/cpus 2>/dev/null
    echo "stune top-app:"
    cat /dev/stune/top-app/tasks 2>/dev/null
    echo "cpuctl top-app uclamp:"
    cat /dev/cpuctl/top-app/cpu.uclamp.min 2>/dev/null
    cat /dev/cpuctl/top-app/cpu.uclamp.max 2>/dev/null
    echo

    echo "Swap:"
    cat /proc/swaps 2>/dev/null
    echo

    pids="$(find_game_pids)"
    echo "Free Fire PIDs: $pids"
    for pid in $pids; do
        echo "--- PID $pid ---"
        list_threads "$pid"
    done
}

diagnose "$@"
