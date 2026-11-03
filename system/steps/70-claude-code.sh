# Claude Code, from Anthropic's apt repository (stable channel).
#
# The signing key is stored as-is (ASCII-armored .asc, which apt accepts) in
# /etc/apt/keyrings and referenced with signed-by, so it only vouches for
# this repository. The package is the `claude` binary; apt updates it like
# everything else.

key=/etc/apt/keyrings/claude-code.asc

tmp="$(mktemp)"
wget -qO "$tmp" https://downloads.claude.ai/keys/claude-code.asc
install -d -m 0755 /etc/apt/keyrings
write_file "$key" 0644 < "$tmp"
rm -f "$tmp"
key_changed=$CHANGED

write_file /etc/apt/sources.list.d/claude-code.list <<EOF
deb [signed-by=$key] https://downloads.claude.ai/claude-code/apt/stable stable main
EOF

if [[ $key_changed -eq 1 || $CHANGED -eq 1 ]]; then apt_update; fi
apt_install claude-code

verify "apt reads Anthropic's repository" apt_knows_source downloads.claude.ai
verify_installed claude-code
verify "claude on PATH" command -v claude
