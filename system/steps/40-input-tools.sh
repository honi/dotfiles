# libinput tools for the touchscreen and touchpad.
#
# The kernel and libinput handle the touchscreen and touchpad with no setup.
# libinput-tools adds `libinput list-devices` and `libinput debug-events`,
# which show what libinput sees: devices and their capabilities, and live
# touch, gesture and key events (key names and codes for key bindings).

apt_install libinput-tools

verify_installed libinput-tools
