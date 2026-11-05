# Dark/light theme switch: ~/.local/bin/theme (status, toggle, dark, light,
# apply).
#
# Switching sets GNOME's color-scheme and GTK theme (GTK apps, Electron apps,
# Zed in system mode and websites follow). Dark uses the Dracula GTK theme and
# light uses Adwaita. The mode is saved in ~/.local/state/theme, and a user
# service re-applies it at login, since Regolith resets the GTK theme to the
# look's own then.
{ config, ... }:
{
  home.file.".local/bin/theme" = {
    executable = true;
    source = ../files/theme.sh;
  };

  systemd.user.services.theme = {
    Unit = {
      Description = "Apply the saved dark/light theme";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/theme apply";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
