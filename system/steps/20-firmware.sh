# Device firmware and CPU microcode from trixie-backports.
#
# The kernel loads these files from /lib/firmware when a driver starts:
#   firmware-iwlwifi        Wi-Fi 7 BE211 and Intel Bluetooth
#   firmware-intel-graphics Xe3 GPU: display (DMC), GuC/HuC scheduling and
#                           media, GSC security
#   firmware-misc-nonfree   other Intel and USB devices
#   firmware-sof-signed     Intel audio DSP firmware (this board uses the
#                           HDA driver, kept for completeness)
#   intel-microcode         CPU microcode, loaded early from the initramfs
#
# Backports versions match the backports kernel. New firmware is picked up
# when the driver loads, so a reboot applies it.

firmware=(
  firmware-iwlwifi
  firmware-intel-graphics
  firmware-misc-nonfree
  firmware-sof-signed
  intel-microcode
)
apt_install_backports "${firmware[@]}"

verify_installed "${firmware[@]}"
verify "firmware is the newest trixie-backports version" backports_current "${firmware[@]}"
