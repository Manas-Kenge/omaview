#!/usr/bin/env bash
set -euo pipefail

sample() {
  awk '/^cpu /{printf "%d %d %d %d %d %d %d %d %d\n", $2,$3,$4,$5,$6,$7,$8,$9,$2+$3+$4+$5+$6+$7+$8+$9; exit}' /proc/stat
}

read u1 n1 s1 i1 iw1 q1 sq1 st1 t1 <<< "$(sample)"
sleep 0.35
read u2 n2 s2 i2 iw2 q2 sq2 st2 t2 <<< "$(sample)"

total=$((t2 - t1))
idle=$(( (i2 + iw2) - (i1 + iw1) ))
cpu=0
(( total > 0 )) && cpu=$(( (total - idle) * 100 / total ))

ram=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%d", (t>0?(t-a)*100/t:0)}' /proc/meminfo)

printf 'cpu|%d\nram|%d\n' "$cpu" "$ram"
