# trixie-backports apt source.
#
# Backports are newer versions of selected packages (kernel, firmware, Mesa),
# rebuilt for Debian 13. Adding the source doesn't change anything by itself:
# apt gives backports a low priority (100), so a package only comes from there
# when asked with `-t trixie-backports` or when a pin says so.

write_file /etc/apt/sources.list.d/backports.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

apt_update

verify "apt reads trixie-backports" apt_knows_source trixie-backports
