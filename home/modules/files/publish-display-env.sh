#!/usr/bin/env bash
#
# Give gnome-session Sway's WAYLAND_DISPLAY and DISPLAY.
#
# gnome-session starts before Sway, so its environment has no display, and
# the apps it starts from XDG autostart files inherit that and fail. GNOME's
# own compositor passes these values with SessionManager.Setenv, which
# gnome-session accepts only while the session is starting. Regolith's Sway
# config doesn't, so this does.
#
# Runs as ExecStartPost of regolith-wayland.service: gnome-session waits for
# that service before it starts autostart apps, and still accepts Setenv.
# Sway imports both variables into the systemd user environment from its
# config, possibly a moment after it reports ready, so this waits up to 5
# seconds for them. Logout clears them, so any value found is this session's.
#
# Always exits 0: a failure here must not fail the session service, whose
# OnFailure logs out.

set -uo pipefail

env=""
for _ in $(seq 50); do
  env=$(systemctl --user show-environment)
  grep -q '^WAYLAND_DISPLAY=' <<<"$env" && break
  sleep 0.1
done

for name in WAYLAND_DISPLAY DISPLAY; do
  value=$(sed -n "s/^$name=//p" <<<"$env")
  if [ -z "$value" ]; then
    echo "$name not in the systemd user environment, not passed on" >&2
    continue
  fi
  if gdbus call --session \
      --dest org.gnome.SessionManager \
      --object-path /org/gnome/SessionManager \
      --method org.gnome.SessionManager.Setenv "$name" "$value" >/dev/null; then
    echo "gnome-session: $name=$value"
  else
    echo "gnome-session refused $name" >&2
  fi
done

exit 0
