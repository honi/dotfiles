{ ... }:
{
  xdg.configFile."foot/foot.ini".text = ''
    [main]
    font=RobotoMono Nerd Font:size=11
    pad=8x8
    include=/usr/share/foot/themes/dracula

    [key-bindings]
    # Copy the whole scrollback to the clipboard; foot has no select-all.
    pipe-scrollback=[wl-copy] Control+Shift+a
  '';
}
