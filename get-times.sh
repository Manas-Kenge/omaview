#!/usr/bin/env bash
set -euo pipefail

epoch="${1:?usage: get-times.sh <epoch> [<iana-zone> ...]}"
shift
format='%H:%M|%I:%M|%p|%Y-%m-%d|%a|%z|%Z'

local_out=$(date -d "@$epoch" +"$format" 2>/dev/null || true)
printf '__local__|%s\n' "${local_out:-ERROR}"

for zone in "$@"; do
  zone_out=$(TZ="$zone" date -d "@$epoch" +"$format" 2>/dev/null || true)
  printf '%s|%s\n' "$zone" "${zone_out:-ERROR}"
done
