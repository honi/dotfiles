# foot terminal settings.
#
#   font     RobotoMono Nerd Font, the same family as the bar and GTK
#            monospace text
#   pad      8px between the window edge and the text
#   include  the Dracula color scheme from foot-themes
{ ... }:
{
  xdg.configFile."foot/foot.ini".text = ''
    [main]
    font=RobotoMono Nerd Font:size=11
    pad=8x8
    include=/usr/share/foot/themes/dracula
  '';
}
