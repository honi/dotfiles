# Microphone noise suppression plugin: DeepFilterNet as a LADSPA plugin.
#
# DeepFilterNet is a neural speech enhancer that removes noise and some room
# reverb. PipeWire's filter-chain loads its LADSPA plugin to make an enhanced
# copy of a microphone. Debian doesn't package it, so this installs the
# project's release binary into /usr/local/lib/ladspa.
#
# The release is pinned and the installed plugin is checked against its
# SHA-256 digest (recorded here; the project publishes none, so it was computed
# from the downloaded asset). The step downloads again only when the installed
# file differs. To update, change the version and the digest.

version=v0.5.6
sha256=2ca3205c2911d389604a826a240e745597d50252b5cab81c8248252b335e2236
url="https://github.com/Rikorose/DeepFilterNet/releases/download/$version/libdeep_filter_ladspa-${version#v}-x86_64-unknown-linux-gnu.so"
dest=/usr/local/lib/ladspa/libdeep_filter_ladspa.so

plugin_current() { [[ -f "$dest" ]] && sha256sum -c --status - <<<"$sha256  $dest"; }

if plugin_current; then
  log "unchanged: $dest ($version)"
else
  log "installing DeepFilterNet $version"
  tmp="$(mktemp -d)"
  wget -qO "$tmp/plugin.so" "$url"
  sha256sum -c --status - <<<"$sha256  $tmp/plugin.so" \
    || { rm -rf "$tmp"; fail "the downloaded plugin doesn't match digest $sha256"; }
  install -D -m 0644 "$tmp/plugin.so" "$dest"
  rm -rf "$tmp"
fi

verify "DeepFilterNet plugin installed" plugin_current
