# Bluetooth daemon and tray applet.
#
# bluez provides bluetoothd, which talks to the controller and serves
# pairing and connections over D-Bus to bluetoothctl and desktop tools.
# blueman provides blueman-applet, a tray icon whose menu connects paired
# devices, and blueman-manager for scanning and pairing.

apt_install bluez blueman
systemctl enable --now bluetooth >/dev/null
log "bluetooth service enabled"

verify_installed bluez blueman
verify "bluetooth service enabled" systemctl is-enabled bluetooth
verify "bluetooth service running" systemctl is-active bluetooth
