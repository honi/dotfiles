# fwupd: BIOS and embedded controller updates.
#
# fwupd downloads firmware for the mainboard and peripherals from LVFS (the
# Linux Vendor Firmware Service), when the vendor publishes it there.
# `fwupdmgr refresh` downloads the current metadata. Installing an update
# reboots into the firmware updater, so it isn't done here.

apt_install fwupd
fwupdmgr refresh --force >/dev/null 2>&1 || warn "fwupdmgr refresh failed (no network?); run it later"

verify_installed fwupd
