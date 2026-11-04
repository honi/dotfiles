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
    fi
    ;;
  on)
    if [[ -e "$saved" ]]; then
      (( current == 0 )) && cat "$saved" >"$led"
      rm -f "$saved"
    fi
    ;;
  *)
    echo "usage: ${0##*/} off|on" >&2
    exit 2
    ;;
esac
