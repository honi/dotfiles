# Daily automatic security upgrades.
#
# The package installs with no periodic trigger: apt's daily timers only run
# it when APT::Periodic::Unattended-Upgrade is set. 20auto-upgrades
# switches on the daily package-list refresh and upgrade run. The package's own
# 50unattended-upgrades keeps the allowed origins to Debian security.

apt_install unattended-upgrades
put_file /etc/apt/apt.conf.d/20auto-upgrades

verify_installed unattended-upgrades
verify "daily package-list refresh enabled" grep -q 'Update-Package-Lists "1"' /etc/apt/apt.conf.d/20auto-upgrades
verify "daily unattended upgrade enabled" grep -q 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades
verify "apt-daily-upgrade timer enabled" systemctl is-enabled apt-daily-upgrade.timer
