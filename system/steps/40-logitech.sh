# Logitech Unifying receiver and mouse management.
#
# Solaar lists the devices paired to a Unifying receiver (battery, DPI,
# pairing). Its package installs the udev rules that give the logged-in user
# access to the receiver's hidraw device.

apt_install solaar

verify_installed solaar
verify "solaar udev rules installed" test -f /usr/lib/udev/rules.d/60-solaar.rules
