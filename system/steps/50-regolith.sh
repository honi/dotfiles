# Regolith desktop (Regolith 3.4 for Debian trixie), from Regolith's apt
# repository: the Sway (Wayland) session with the Dracula look.
#
# The key is stored de-armored in /usr/share/keyrings and referenced with
# signed-by, so it only vouches for this repository, not for all of apt.
# "v3.4" is the component: the Regolith release this machine follows. Moving
# to a later release means changing it here. Check
# https://regolith-desktop.com/docs/using-regolith/install/ before upgrading.
#
#   regolith-desktop             core: settings daemons, launcher (ilia),
#                                notifications (rofication), bar, configs
#   regolith-session-sway        the Wayland session, running Regolith's
#                                build of Sway (sway-regolith)
#   regolith-look-dracula        theme: colors, GTK theme, fonts, bar look
#   xdg-desktop-portal-regolith  portals: screen sharing, file dialogs
#   gnome-session-common         gnome-session's systemd units; without them
#                                the session starts in a fallback mode where
#                                regolith-wayland.target (idle, lock,
#                                display and input daemons) never starts
#   bc                           used by the idle dim command; no Regolith
#                                package depends on it
#
# Regolith's own configuration lives under /usr/share/regolith.
#
# Plymouth (boot splash) is kept out: it takes over the console during boot,
# so the LUKS prompt loses the console font. A Regolith dependency recommends
# it; priority -1 makes plymouth* uninstallable, so apt skips the
# recommendation. The pin has to be in place before the install below.

fetch_keyring https://archive.regolith-desktop.com/regolith.key \
  /usr/share/keyrings/regolith-archive-keyring.gpg
key_changed=$CHANGED

write_file /etc/apt/sources.list.d/regolith.list <<'EOF'
deb [arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] https://archive.regolith-desktop.com/debian/stable trixie v3.4
EOF

if [[ $CHANGED -eq 1 || $key_changed -eq 1 ]]; then apt_update; fi

# No boot splash. Text console only during boot.
write_file /etc/apt/preferences.d/no-plymouth <<'EOF'
Package: plymouth* libplymouth5
Pin: release *
Pin-Priority: -1
EOF

apt_install \
  regolith-desktop \
  regolith-session-sway \
  regolith-look-dracula \
  xdg-desktop-portal-regolith \
  gnome-session-common \
  bc

verify "Regolith keyring present" test -s /usr/share/keyrings/regolith-archive-keyring.gpg
verify "apt reads the Regolith repository" apt_knows_source archive.regolith-desktop.com
verify_installed regolith-desktop regolith-session-sway regolith-look-dracula xdg-desktop-portal-regolith gnome-session-common
verify "plymouth not installed" not_installed plymouth
verify "a Wayland session for the greeter" compgen -G "/usr/share/wayland-sessions/*.desktop"
