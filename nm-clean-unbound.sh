#!/bin/bash
set -e

FLAG=/var/lib/nm-clean-once
[ -f "$FLAG" ] && exit 0

nmcli -t -f RUNNING general | grep -q running || exit 0

mapfile -t uuids < <(
  nmcli -t -f UUID,DEVICE connection show |
  awk -F: '$2=="" || $2=="--" {print $1}'
)

for uuid in "${uuids[@]}"; do
  nmcli connection delete uuid "$uuid"
done

touch "$FLAG"
EOF
