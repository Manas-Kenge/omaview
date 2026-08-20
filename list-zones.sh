#!/usr/bin/env bash
set -euo pipefail

timedatectl list-timezones | jq -R '
  split("/") as $parts
  | { value: ., label: ($parts[-1] | gsub("_"; " ")), description: . }
' | jq -s '.'
