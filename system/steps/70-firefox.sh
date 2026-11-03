# Firefox from Mozilla's apt repository.
#
# Debian ships Firefox ESR; Mozilla's repository has the current release,
# updated with apt like everything else.
#   - The signing key is stored as-is (ASCII-armored .asc, which apt accepts)
#     in /etc/apt/keyrings.
#   - The preferences file gives every package from packages.mozilla.org
#     priority 1000, above Debian's 500, so `firefox` comes from Mozilla even
#     though Debian has a package of the same name, and apt follows Mozilla's
#     versions from then on.

key=/etc/apt/keyrings/packages.mozilla.org.asc

tmp="$(mktemp)"
wget -qO "$tmp" https://packages.mozilla.org/apt/repo-signing-key.gpg
install -d -m 0755 /etc/apt/keyrings
write_file "$key" 0644 < "$tmp"
rm -f "$tmp"
key_changed=$CHANGED

write_file /etc/apt/sources.list.d/mozilla.list <<EOF
deb [signed-by=$key] https://packages.mozilla.org/apt mozilla main
EOF
list_changed=$CHANGED

write_file /etc/apt/preferences.d/mozilla <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

if [[ $key_changed -eq 1 || $list_changed -eq 1 || $CHANGED -eq 1 ]]; then apt_update; fi
apt_install firefox

verify "apt reads Mozilla's repository" apt_knows_source packages.mozilla.org
verify_installed firefox
verify "firefox comes from Mozilla's repository" installed_from firefox packages.mozilla.org
