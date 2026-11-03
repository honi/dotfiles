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
# Nothing is restarted here, so an SSH session over Ethernet stays up; the
# handover happens at the next reboot.

apt_install network-manager

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

verify_installed network-manager
verify "NetworkManager enabled" systemctl is-enabled NetworkManager
verify "ifupdown only manages loopback" only_loopback_in_ifupdown
