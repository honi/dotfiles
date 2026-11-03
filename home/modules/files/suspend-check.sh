#!/usr/bin/env bash
#
# Measure battery drain during one suspend.
#
# Records the battery's energy, suspends the machine, waits until it wakes,
# then prints how long it was suspended, how much of that time the chip spent
# in its deepest sleep state, and the average power drawn while asleep.
#
# Usage: suspend-check
# Sleep for at least 30 minutes (or overnight) for a reliable number: the
# energy readings include a few seconds before and after the sleep.
#
# Reading the result:
#   drain       average power while suspended; a few hundred mW is good for
#               s2idle, watts means something kept the system awake
#   deep sleep  share of the suspended time the chip spent in its lowest power
#               state; close to 100% is ideal

set -Eeuo pipefail
trap 'echo "stopped at line $LINENO: $BASH_COMMAND" >&2' ERR

stats=/sys/power/suspend_stats
bats=(/sys/class/power_supply/BAT*)
bat="${bats[0]}"
[[ -d "$bat" ]] || { echo "no battery found" >&2; exit 1; }

# Battery energy in µWh. Some batteries report energy directly (energy_now,
# µWh); others report charge (charge_now, µAh) and voltage (voltage_now, µV),
# whose product is the energy.
energy() {
  if [[ -r "$bat/energy_now" ]]; then
    cat "$bat/energy_now"
  else
    echo $(( $(cat "$bat/charge_now") * $(cat "$bat/voltage_now") / 1000000 ))
  fi
}

# Reading kernel messages needs root or the systemd-journal group.
journal() {
  local groups
  groups=" $(id -nG) "
  if [[ "$groups" == *" systemd-journal "* || "$groups" == *" adm "* ]]; then
    journalctl "$@"
  else
    sudo journalctl "$@"
  fi
}

e0="$(energy)"
c0="$(cat "$bat/capacity")"
ok0="$(cat "$stats/success")"
fail0="$(cat "$stats/fail")"

echo "battery at ${c0}%, suspending..."
t0="$(date +%s)"
systemctl suspend

# The suspend counters change once the system has suspended and resumed
# (success) or the attempt failed (fail).
while [[ "$(cat "$stats/success")" == "$ok0" && "$(cat "$stats/fail")" == "$fail0" ]]; do
  sleep 1
done
if [[ "$(cat "$stats/fail")" != "$fail0" ]]; then
  echo "suspend failed: see journalctl -b | grep -i suspend" >&2
  exit 1
fi

t1="$(date +%s)"
sleep 2
e1="$(energy)"
c1="$(cat "$bat/capacity")"
echo "resumed, reading the suspend log..."

# Time suspended: between the kernel's last "PM: suspend entry" and "exit".
# If the log can't be read, fall back to the wall-clock time from the suspend
# command to the wake-up, which is a second or two longer.
times="$(journal -b -o short-unix | grep -E 'PM: suspend (entry|exit)' | tail -2 | awk '{printf "%d ", $1}' || true)"
read -r entry exit_ <<< "$times" || true
if [[ -n "${entry:-}" && -n "${exit_:-}" ]] && (( exit_ > entry )); then
  slept=$(( exit_ - entry ))
  source_="kernel log"
else
  slept=$(( t1 - t0 ))
  source_="wall clock (suspend log not readable)"
fi
(( slept > 0 )) || { echo "suspend took no time; did it suspend?" >&2; exit 1; }

# Time in the deepest hardware sleep state, if the kernel reports it (µs).
hw=""
if [[ -r "$stats/last_hw_sleep" ]]; then hw=$(( $(cat "$stats/last_hw_sleep") / 1000000 )); fi

used=$(( (e0 - e1) / 1000 ))   # mWh

printf 'suspended:  %d min (%d s, from %s)\n' $(( slept / 60 )) "$slept" "$source_"
if [[ -n "$hw" ]]; then
  printf 'deep sleep: %d s (%d%% of suspended time)\n' "$hw" $(( hw * 100 / slept ))
fi
printf 'battery:    %d%% -> %d%%, %d mWh used\n' "$c0" "$c1" "$used"
printf 'drain:      %d mW\n' $(( used * 3600 / slept ))
