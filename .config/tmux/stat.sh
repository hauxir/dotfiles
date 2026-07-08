#!/bin/sh
# Single-process tmux status helper: prints CPU% and MEM% with theme colors.
#
# Deliberately ONE awk process with NO pipes. tmux runs status `#()` commands
# via `sh -c` and tears them down on the next refresh; any pipeline here would
# orphan its children (top|awk, echo|sed, ...) onto PID 1 as zombies. Keeping
# this to a single short-lived process means tmux owns it and reaps it cleanly.
#
# CPU% is a delta between two /proc/stat snapshots; the previous snapshot is
# cached in a tmp file so we never need a second sampling process or a sleep.
cache="${TMPDIR:-/tmp}/.tmux-cpu.$(id -u)"

exec awk -v cache="$cache" '
BEGIN {
  # --- current CPU totals (aggregate line of /proc/stat) ---
  getline line < "/proc/stat"; close("/proc/stat")
  n = split(line, a, /[ \t]+/)
  total = 0
  for (i = 2; i <= n; i++) total += a[i]
  idle = a[5] + a[6]              # idle + iowait

  # --- delta against the previous snapshot ---
  if ((getline prev < cache) > 0) {
    split(prev, p, " ")
    dt = total - p[1]
    di = idle  - p[2]
    if (dt > 0) cpu = (dt - di) * 100 / dt
  }
  close(cache)
  print total, idle > cache       # save snapshot for next refresh
  close(cache)

  # --- memory (used / total) ---
  while ((getline ml < "/proc/meminfo") > 0) {
    if (ml ~ /^MemTotal:/)     { split(ml, m, /[ \t]+/); mt = m[2] }
    if (ml ~ /^MemAvailable:/) { split(ml, m, /[ \t]+/); ma = m[2] }
  }
  close("/proc/meminfo")
  if (mt > 0) mem = (mt - ma) * 100 / mt

  printf "#[fg=#e0af68] cpu %3.0f%% #[fg=#565f89]\342\226\217#[fg=#9ece6a] mem %3.0f%% ", cpu, mem
}'
