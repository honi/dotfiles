#!/usr/bin/env bash
#
# Turn the keyboard backlight off, or bring it back.
#
#   off   saves the current brightness and sets it to 0. Does nothing when the
#         light is already off, so a second "off" (idle, then sleep) keeps the
#         first saved value.
#   on    restores the saved brightness, then forgets it. Does nothing when
#         nothing was saved, or when the light was turned on in the meantime
#         (a brightness key).
#
# Logs each change to the journal under the tag kbd-backlight.
#
# Does nothing on a machine without a keyboard backlight.

set -u

led=""
for f in /sys/class/leds/*kbd_backlight/brightness; do
  [[ -w "$f" ]] && led="$f" && break
done
[[ -n "$led" ]] || exit 0

saved="${XDG_RUNTIME_DIR:-/tmp}/kbd-backlight.saved"
current="$(cat "$led")"

case "${1:-}" in
  off)
    if (( current > 0 )) && [[ ! -e "$saved" ]]; then
      echo "$current" >"$saved"
      echo 0 >"$led"
      logger -t kbd-backlight "off (was $current)"
    fi
    ;;
  on)
    if [[ -e "$saved" ]]; then
      if (( current == 0 )); then
        cat "$saved" >"$led"
        logger -t kbd-backlight "on (restored $(cat "$saved"))"
      else
        logger -t kbd-backlight "on skipped (already $current)"
      fi
      rm -f "$saved"
    fi
    ;;
  *)
    echo "usage: ${0##*/} off|on" >&2
    exit 2
    ;;
esac
