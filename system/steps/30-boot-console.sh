# GRUB menu, console font and kernel command line: how the console looks
# during boot.
#
# GRUB menu: shown for three seconds, from /etc/default/grub.d/menu.cfg,
# then GRUB boots the default entry. GRUB's font can't be enlarged (with
# Secure Boot it only loads fonts from its signed image), so the menu is drawn
# at 1024x768 and the panel scales it up, stretched to 3:2. The firmware
# doesn't offer half the native mode.
#
# GPU driver in the initramfs, from /etc/initramfs-tools/hooks/early-kms: it
# switches the console to the native 2880x1920 before the LUKS passphrase
# prompt. Without it, the prompt stays in the mode GRUB drew its menu in.
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

put_file /etc/default/grub.d/menu.cfg
if [[ $CHANGED -eq 1 ]]; then needs_grub "GRUB menu"; fi

put_file /etc/initramfs-tools/hooks/early-kms 0755
if [[ $CHANGED -eq 1 ]]; then needs_initramfs "GPU driver in the initramfs"; fi

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

verify "GRUB menu shown" grub_setting_is GRUB_TIMEOUT_STYLE menu
verify "GRUB timeout: 3 seconds" grub_setting_is GRUB_TIMEOUT 3
verify "GRUB menu at 1024x768" grub_setting_is GRUB_GFXMODE 1024x768,auto
verify "GPU driver hook for the initramfs is executable" test -x /etc/initramfs-tools/hooks/early-kms
verify "console font is Terminus 16x32" grep -qx 'FONTFACE="Terminus"' "$conf"
verify "kernel command line: $cmdline" grub_setting_is GRUB_CMDLINE_LINUX_DEFAULT "$cmdline"
