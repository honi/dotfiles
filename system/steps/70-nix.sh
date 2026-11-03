# Nix, from Debian's packages.
#
# nix-setup-systemd installs the Nix binaries (nix-bin) and sets Nix up in
# multi-user mode: the nix-daemon service owns /nix/store (on its own LV) and
# builds packages on behalf of users. Users talk to the daemon through its
# socket, which only members of the nix-users group may use.
#
# /etc/nix/nix.conf is Nix's system-wide config: Debian's, plus
# experimental-features for the `nix` command and flakes.
#
# The group applies after a reboot: the long-lived systemd user manager
# keeps the old group list across a plain logout.

apt_install nix-setup-systemd

if in_group "$TARGET_USER" nix-users; then
  log "unchanged: $TARGET_USER is in nix-users"
else
  usermod -aG nix-users "$TARGET_USER"
  log "added $TARGET_USER to nix-users"
  needs_reboot "nix-users group membership (a logout can leave the user manager with the old groups)"
fi

conf=/etc/nix/nix.conf
backup_once "$conf"
put_file "$conf"
# the daemon reads nix.conf at start; restart it only if it's running
if [[ $CHANGED -eq 1 ]]; then systemctl try-restart nix-daemon; fi

# Socket activation: systemd listens on the daemon socket and starts
# nix-daemon on the first connection. The package starts nix-daemon.service
# itself, and a socket refuses to listen while its service is already running
# ("Socket service nix-daemon.service already active"), so stop the service
# first; the socket brings it back on demand.
if ! systemctl is-active --quiet nix-daemon.socket; then
  systemctl stop nix-daemon.service
fi
systemctl enable --now nix-daemon.socket >/dev/null

verify_installed nix-setup-systemd
verify "$TARGET_USER in nix-users" in_group "$TARGET_USER" nix-users
verify "flakes enabled in $conf" grep -qx "experimental-features = nix-command flakes" "$conf"
verify "nix-daemon.socket enabled" systemctl is-enabled nix-daemon.socket
verify "nix-daemon.socket listening" systemctl is-active nix-daemon.socket
