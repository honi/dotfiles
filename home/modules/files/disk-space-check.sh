#!/bin/sh
# Notify when a filesystem passes the threshold (percent used).
threshold=${THRESHOLD:-75}
df --local --output=pcent,target -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs | tail -n +2 | while read -r pcent target; do
  used=${pcent%\%}
  if [ "$used" -ge "$threshold" ]; then
    notify-send -u critical -a "Disk space" -i dialog-warning "High disk usage" "$target is $pcent full"
  fi
done
