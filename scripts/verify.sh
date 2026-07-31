#!/system/bin/sh

verify_model() {
    expected="${MODEL:-SM-G981N}"
    model="$(getprop ro.product.model)"
    [ "$model" = "$expected" ]
}

verify_platform() {
    expected="${PLATFORM:-kona}"
    plat="$(getprop ro.board.platform)"
    [ "$plat" = "$expected" ]
}

verify_cpu_paths() {
    [ -d /sys/devices/system/cpu/cpufreq/policy0 ] || return 1
    [ -d /sys/devices/system/cpu/cpufreq/policy4 ] || return 1
    [ -d /sys/devices/system/cpu/cpufreq/policy7 ] || return 1
    return 0
}

verify_gpu_paths() {
    [ -d /sys/class/kgsl/kgsl-3d0 ] || return 1
    return 0
}

verify_memory_paths() {
    [ -e /proc/swaps ] || return 1
    return 0
}

verify_cgroup_paths() {
    [ -d /dev/cpuset/top-app ] || return 1
    [ -d /dev/stune/top-app ] || return 1
    [ -d /dev/cpuctl/top-app ] || return 1
    return 0
}

verify_device() {
    verify_model && verify_platform && verify_cpu_paths && verify_gpu_paths && verify_memory_paths && verify_cgroup_paths
}
