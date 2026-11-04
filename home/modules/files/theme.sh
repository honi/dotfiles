#!/usr/bin/env bash
# Dark/light theme switch: theme [status|toggle|dark|light|apply]
#
# The mode is kept in ~/.local/state/theme (dark when missing). Switching sets
# GNOME's color-scheme and GTK theme. `apply` re-applies the saved mode (the
# login service runs it).

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/theme"

mode() {
  local saved
  saved=$(cat "$state_file" 2>/dev/null)
  echo "${saved:-dark}"
}

apply() {
  local m gtk
  m=$(mode)
  if [[ $m == light ]]; then
    gtk=Adwaita
  else
    gtk=Dracula
  fi

  gsettings set org.gnome.desktop.interface color-scheme "prefer-$m"
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
}

set_mode() {
  mkdir -p "$(dirname "$state_file")"
  echo "$1" >"$state_file"
  apply
}

case "${1:-status}" in
  status)
    # Nerd Font Font Awesome sun (light) and moon (dark).
    if [[ $(mode) == light ]]; then
      echo $'{"text": "\uf185", "state": "Idle"}'
    else
      echo $'{"text": "\uf186", "state": "Idle"}'
    fi
    ;;
  toggle)
    if [[ $(mode) == light ]]; then set_mode dark; else set_mode light; fi
    ;;
  dark | light) set_mode "$1" ;;
  apply) apply ;;
  *) echo "usage: theme [status|toggle|dark|light|apply]" >&2; exit 2 ;;
esac
