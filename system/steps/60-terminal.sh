# Terminal: foot as the default terminal.
#
# foot is a Wayland-native terminal; foot-themes ships color schemes
# (Dracula included) under /usr/share/foot/themes.
#
# x-terminal-emulator is Debian's alternatives link for "the default
# terminal". Regolith's Super+Enter runs it, and so do ilia's terminal mode
# and other apps' "open in terminal". `update-alternatives --set` points it at
# foot and switches the link to manual mode, so installing another terminal
# later doesn't change it.

apt_install \
  foot \
  foot-themes
if [[ "$(readlink -f /etc/alternatives/x-terminal-emulator)" == /usr/bin/foot ]]; then
  log "unchanged: x-terminal-emulator is foot"
else
  update-alternatives --set x-terminal-emulator /usr/bin/foot
fi

verify_installed foot foot-themes
verify "x-terminal-emulator is foot" test "$(readlink -f /etc/alternatives/x-terminal-emulator)" = /usr/bin/foot
