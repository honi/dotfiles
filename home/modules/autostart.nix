# Apps started with the session, from XDG autostart files
# (~/.config/autostart, /etc/xdg/autostart).
#
# gnome-session runs the autostart files, and it starts before Sway, so on
# its own it has no WAYLAND_DISPLAY or DISPLAY and the GUI apps it starts
# exit. A drop-in on regolith-wayland.service runs publish-display-env while
# the session starts, which hands gnome-session Sway's values. The drop-in
# goes in ~/.local/share/systemd/user, not ~/.config: Home Manager restarts
# units whose files change there on switch, and restarting this one would
# end the session.
{ config, ... }:
let
  script = ".local/bin/publish-display-env";
in
{
  home.file.${script} = {
    executable = true;
    source = ../files/publish-display-env.sh;
  };

  xdg.dataFile."systemd/user/regolith-wayland.service.d/publish-display-env.conf".text = ''
    [Service]
    ExecStartPost=-${config.home.homeDirectory}/${script}
  '';
}
