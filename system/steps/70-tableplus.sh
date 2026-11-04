# TablePlus database client from TablePlus's apt repository.
#
# The signing key is stored as-is (ASCII-armored .asc, which apt accepts) in
# /etc/apt/keyrings and referenced with Signed-By, so it only vouches for this
# repository.

key=/etc/apt/keyrings/tableplus.asc
tmp="$(mktemp)"
wget -qO "$tmp" https://deb.tableplus.com/apt.tableplus.com.gpg.key
install -d -m 0755 /etc/apt/keyrings
write_file "$key" 0644 < "$tmp"
rm -f "$tmp"
key_changed=$CHANGED

write_file /etc/apt/sources.list.d/tableplus.sources <<EOF
Types: deb
URIs: https://deb.tableplus.com/debian
Suites: tableplus
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: $key
EOF

if [[ $key_changed -eq 1 || $CHANGED -eq 1 ]]; then apt_update; fi
apt_install tableplus

verify "apt reads TablePlus's repository" apt_knows_source deb.tableplus.com
verify_installed tableplus
verify "tableplus installed from TablePlus's repository" installed_from tableplus deb.tableplus.com
