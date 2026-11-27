#!/usr/bin/env bash
#
# Keep the screen on while an app records from a microphone (a call).
#
# Every 10 seconds, checks for a recording stream (a PulseAudio source
# output). While one exists, tells Sway to inhibit idle on every window, which
# blocks swayidle's dim, screen-off, lock and suspend. When the last one ends,
# or this exits, restores the rule that only fullscreen windows inhibit idle.
#
# Ignored streams: the noise-suppressed mic's own capture, which is always
# present, and level meters (peak-detect streams such as pavucontrol's).
# Windows opened during a call don't get the inhibitor.

set -uo pipefail

interval=10

# Prints the number of source outputs that are real recordings.
recordings() {
  pactl list source-outputs | awk '
    function flush() { if (inblock && !skip) n++ }
    /^Source Output #/ { flush(); inblock = 1; skip = 0; next }
    /node.name = "capture.noise_suppressed_mic"/ { skip = 1 }
    /stream.monitor = "true"/ { skip = 1 }
    /application.id = "org.pulseaudio.pavucontrol"/ { skip = 1 }
    END { flush(); print n + 0 }
  '
}

inhibiting=""

release() {
  swaymsg '[all] inhibit_idle fullscreen' >/dev/null
  inhibiting=""
}

on_exit() {
  [[ -n "$inhibiting" ]] && release
}
trap on_exit EXIT
trap 'exit 0' TERM INT

while true; do
  if (( $(recordings) > 0 )); then
    if [[ -z "$inhibiting" ]]; then
      swaymsg '[all] inhibit_idle open' >/dev/null
      inhibiting=1
      echo "call: inhibiting idle"
    fi
  elif [[ -n "$inhibiting" ]]; then
    release
    echo "call ended: restored idle"
  fi
  sleep "$interval" &
  wait $!
done
