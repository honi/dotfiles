# NetworkManager for Wi-Fi and Ethernet.
#
# NetworkManager manages every interface that isn't listed in
# /etc/network/interfaces (ifupdown's file). The Debian installer lists the
# network adapter used during install there (for example the Ethernet
# expansion card, allow-hotplug/iface enx...), which keeps ifupdown in charge
# of it. The file is replaced with one that only configures loopback, which
# hands every other interface to NetworkManager after the next boot. The
# installer writes this file; no package owns it.
#
# systemd-resolved is the DNS resolver. It keeps DNS servers and domains per
# network interface, so a VPN can answer for its own domains while everything
# else keeps using the normal resolver. NetworkManager and VPN clients register
# their DNS with it, and /etc/resolv.conf points at its local stub. Debian
# ships it as a separate package.
#
# Nothing is restarted here, so an SSH session over Ethernet stays up; the
# handovers happen at the next reboot.

apt_install network-manager

if ! is_installed systemd-resolved; then needs_reboot "DNS moves to systemd-resolved"; fi
apt_install systemd-resolved

backup_once /etc/network/interfaces
put_file /etc/network/interfaces
if [[ $CHANGED -eq 1 ]]; then needs_reboot "network interfaces move to NetworkManager"; fi

# No interface but lo is configured for ifupdown, in the file or the
# interfaces.d snippets it sources.
only_loopback_in_ifupdown() {
  local others
  others="$(grep -hsE '^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]' \
      /etc/network/interfaces /etc/network/interfaces.d/* \
    | grep -vE '^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+lo([[:space:]]|$)')"
  [[ -z "$others" ]] || { printf '%s\n' "$others" >&2; return 1; }
}

verify_installed network-manager systemd-resolved
verify "NetworkManager enabled" systemctl is-enabled NetworkManager
verify "ifupdown only manages loopback" only_loopback_in_ifupdown
verify "systemd-resolved enabled" systemctl is-enabled systemd-resolved
verify "resolv.conf points at the resolved stub" \
  test "$(readlink -f /etc/resolv.conf)" = /run/systemd/resolve/stub-resolv.conf
