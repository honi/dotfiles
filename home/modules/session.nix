# Log out without confirmation, and the look of the remaining prompts.
{ ... }:
{
  # Super+Shift+E runs whatever sway.prompt.logout says; by default a swaynag
  # confirmation bar whose button runs the logout command. Setting it to that
  # command logs out directly: gnome-session-quit ends the session (and the
  # keyring) cleanly, then Sway exits. Reboot and shut down keep their prompt.
  regolith.xresources."sway.prompt.logout" =
    "/usr/bin/gnome-session-quit --logout --no-prompt && swaymsg exit";

  # swaynag's look, per message type ([warning] is what Regolith's prompts
  # use). Colors are hex without #. Dark red with white Terminus text, like
  # the login and lock screens.
  xdg.configFile."swaynag/config".text = ''
    [warning]
    font=Terminus 12
    background=990000
    text=ffffff
    border=ffffff
    border-bottom=ffffff
    border-bottom-size=2
    button-background=990000
    button-text=ffffff
    button-border-size=1
    button-padding=4
    message-padding=8
  '';
}
