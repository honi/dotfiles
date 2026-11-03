# Disk space warnings.
#
# An hourly systemd user timer runs a script that checks every local disk
# filesystem (df --local, minus RAM-backed and virtual ones) and sends a
# critical desktop notification for each one past the threshold (75% by
# default, THRESHOLD=<n> to override). Notifications show in Regolith's
# counter on the bar; Super+N lists them.
#
# The timer: first run 5 minutes after boot, then 1 hour after each run.
# Home Manager writes the units to ~/.config/systemd/user and enables the
# timer through timers.target.
{ config, ... }:
let
  script = ".local/bin/disk-space-check";
in
{
  home.file.${script} = {
    executable = true;
    source = ./files/disk-space-check.sh;
  };

  systemd.user.services.disk-space-check = {
    Unit.Description = "Warn about high disk usage";
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/${script}";
    };
  };

  systemd.user.timers.disk-space-check = {
    Unit.Description = "Hourly disk space check";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
