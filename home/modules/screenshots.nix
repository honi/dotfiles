# Screenshot keys.
#
# Print Screen is on F11 (it sends KEY_SYSRQ, which Sway names Print).
#   Print        drag an area, copy it to the clipboard
#   Shift+Print  the whole display, to the clipboard
# grimshot's first argument is the action (copy, save, savecopy) and the
# second the target (area, output, screen, active, window). `savecopy` also
# keeps a file in ~/Pictures; --notify before the action adds a notification.
{ ... }:
{
  xdg.configFile."regolith3/sway/config.d/60_screenshots".text = ''
    bindsym Print exec grimshot copy area
    bindsym Shift+Print exec grimshot copy output
  '';
}
