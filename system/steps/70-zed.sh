# Zed editor, from Zed's release tarball (not apt, not Nix).
#
# Neither Debian nor Zed has an apt package. This does what Zed's own
# install.sh does, for the desktop user: the app goes to ~/.local/zed.app,
# ~/.local/bin/zed links to its CLI, and a desktop entry pointing at the
# install goes to ~/.local/share/applications. The release build uses the
# system's Mesa for Vulkan.
#
# Only installs when it's missing: Zed updates itself in place after that,
# which is why it lives in the user's home and is owned by them. To
# reinstall, remove ~/.local/zed.app and run this step again.

app="$TARGET_HOME/.local/zed.app"
url=https://zed.dev/api/releases/stable/latest/zed-linux-x86_64.tar.gz

as_user() { runuser -u "$TARGET_USER" -- "$@"; }

if [[ -x "$app/bin/zed" ]]; then
  log "unchanged: $app (Zed updates itself)"
else
  tmp="$(as_user mktemp -d)"
  log "downloading $url"
  as_user wget -qO "$tmp/zed.tar.gz" "$url"
  as_user mkdir -p "$TARGET_HOME/.local"
  as_user tar -xzf "$tmp/zed.tar.gz" -C "$TARGET_HOME/.local"
  rm -rf "$tmp"
  log "installed: $app"
fi

as_user mkdir -p "$TARGET_HOME/.local/bin" "$TARGET_HOME/.local/share/applications"
as_user ln -sfn "$app/bin/zed" "$TARGET_HOME/.local/bin/zed"

desktop="$TARGET_HOME/.local/share/applications/dev.zed.Zed.desktop"
write_file "$desktop" 0644 <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zed
GenericName=Text Editor
Comment=A high-performance, multiplayer code editor.
TryExec=$app/libexec/zed-editor
StartupNotify=true
Exec=$app/libexec/zed-editor %U
Icon=$app/share/icons/hicolor/512x512/apps/zed.png
Categories=Utility;TextEditor;Development;IDE;
Keywords=zed;
MimeType=text/plain;application/x-zerosize;x-scheme-handler/zed;
Actions=NewWorkspace;

[Desktop Action NewWorkspace]
Exec=$app/libexec/zed-editor --new %U
Name=Open a new workspace
EOF
chown "$TARGET_USER:" "$desktop"

verify "Zed installed in $app" test -x "$app/libexec/zed-editor"
verify "$app owned by $TARGET_USER" test "$(stat -c %U "$app")" = "$TARGET_USER"
verify "zed CLI at ~/.local/bin/zed" test -x "$TARGET_HOME/.local/bin/zed"
verify "desktop entry starts $app" grep -qxF "Exec=$app/libexec/zed-editor %U" "$desktop"
