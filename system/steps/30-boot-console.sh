# GRUB menu, console font and kernel command line: how the console looks
# during boot.
#
# GRUB menu: hidden, from /etc/default/grub.d/menu.cfg. GRUB waits one second
# and boots the default entry; pressing Esc in that second shows the menu. Its
# font can't be enlarged: with Secure Boot, GRUB only loads fonts from its
# signed image, so at 2880x1920 the menu text is tiny.
#
# Console font: Terminus 16x32, from /etc/default/console-setup. The text
# console (TTYs, and the LUKS passphrase prompt in the initramfs) runs at the
# panel's native 2880x1920, where the default font is tiny.
#
# Kernel command line:
#   quiet                hides informational kernel messages
#   loglevel=3           also hides warnings, showing only errors and worse on
#                        screen; everything still goes to the kernel log
#                        (journalctl -k)
#   fbcon=font:TER16x32  the kernel's built-in Terminus 16x32 for messages
#                        printed before the initramfs loads the console font.
#                        Only added when the newest installed kernel (the one
#                        GRUB boots next) was built with it (CONFIG_FONT_TER16x32=y).

put_file /etc/default/grub.d/menu.cfg
if [[ $CHANGED -eq 1 ]]; then needs_grub "GRUB menu"; fi

conf=/etc/default/console-setup
backup_once "$conf"
put_file "$conf"
if [[ $CHANGED -eq 1 ]]; then
  # `setupcon --save-only` copies the selected font and keymap into
  # /etc/console-setup, where the initramfs hook picks them up, so the LUKS
  # prompt uses the same font once the initramfs is rebuilt.
  setupcon --save-only
  needs_initramfs "console font"
fi

cmdline="quiet loglevel=3"
newest_config="$(printf '%s\n' /boot/config-* | sort -V | tail -n 1)"
if grep -q '^CONFIG_FONT_TER16x32=y' "$newest_config" 2>/dev/null; then
  cmdline="$cmdline fbcon=font:TER16x32"
else
  warn "newest kernel ($newest_config) lacks the built-in Terminus font; skipping fbcon=font"
fi

write_file /etc/default/grub.d/cmdline.cfg <<EOF
GRUB_CMDLINE_LINUX_DEFAULT="$cmdline"
EOF
if [[ $CHANGED -eq 1 ]]; then needs_grub "kernel command line"; fi

# The value update-grub will use for a setting: /etc/default/grub, then the
# drop-ins in order, as update-grub reads them.
grub_setting_is() {
  local name="$1" expected="$2" actual
  actual="$(
    set +eu
    # shellcheck source=/dev/null
    . /etc/default/grub
    # shellcheck source=/dev/null
    for f in /etc/default/grub.d/*.cfg; do [[ -e "$f" ]] && . "$f"; done
    printf '%s' "${!name}"
  )"
  [[ "$actual" == "$expected" ]] || { echo "update-grub would use $name=\"$actual\"" >&2; return 1; }
}

verify "GRUB menu hidden" grub_setting_is GRUB_TIMEOUT_STYLE hidden
verify "GRUB timeout: 1 second" grub_setting_is GRUB_TIMEOUT 1
verify "console font is Terminus 16x32" grep -qx 'FONTFACE="Terminus"' "$conf"
verify "kernel command line: $cmdline" grub_setting_is GRUB_CMDLINE_LINUX_DEFAULT "$cmdline"
