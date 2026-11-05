#!/usr/bin/env bash
#
# Keep the machine from suspending on idle while audio plays.
#
# Every 30 seconds, checks whether an audio output is playing (a PipeWire
# sink in the RUNNING state; a paused player leaves it IDLE). While one is,
# holds a logind sleep inhibitor, so swayidle's idle suspend is refused. The
# idle dim, screen-off and lock still happen. Closing the lid still suspends:
# logind ignores inhibitors for the lid switch.
#
# swayidle runs its suspend once per idle period, so a suspend refused during
# playback isn't tried again when the music ends. To make up for it, once
# audio stops while the screen is locked, this suspends the machine as soon
# as the lock is older than the idle suspend time (by then swayidle has
# already tried). Unlocking, or any suspend in between, cancels that.

set -uo pipefail

interval=30
suspend_after=900   # Regolith's idle suspend: sleep-inactive-*-timeout
stats=/sys/power/suspend_stats/success

inhibitor=""
armed=""            # suspend count when audio stopped while locked

playing() { pactl list sinks short | grep -q RUNNING; }

# Seconds since the screen was locked, or nothing when it isn't locked.
lock_age() { ps -o etimes= -C gtklock | sort -n | tail -1 | tr -d ' '; }

release() {
  if [[ -n "$inhibitor" ]]; then
    kill "$inhibitor" 2>/dev/null
    wait "$inhibitor" 2>/dev/null
    inhibitor=""
  fi
}
trap release EXIT
trap 'exit 0' TERM INT

while true; do
  # Take the inhibitor again if it ended on its own.
  if [[ -n "$inhibitor" ]] && ! kill -0 "$inhibitor" 2>/dev/null; then
    inhibitor=""
  fi
  if playing; then
    armed=""
    if [[ -z "$inhibitor" ]]; then
      systemd-inhibit --what=sleep --mode=block --who="Audio sleep inhibitor" \
        --why="Audio is playing" sleep infinity &
      inhibitor=$!
      echo "audio playing: holding the sleep inhibitor"
    fi
  else
    if [[ -n "$inhibitor" ]]; then
      release
      echo "audio stopped: released the sleep inhibitor"
      [[ -n "$(lock_age)" ]] && armed="$(cat "$stats")"
    fi
    if [[ -n "$armed" ]]; then
      age="$(lock_age)"
      if [[ -z "$age" || "$(cat "$stats")" != "$armed" ]]; then
        armed=""
      elif (( age >= suspend_after )); then
        armed=""
        echo "locked for ${age}s with no audio: suspending"
        systemctl suspend
      fi
    fi
  fi
  sleep "$interval" &
  wait $!
done
