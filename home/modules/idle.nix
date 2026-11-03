# Idle: no suspend while audio plays, no dimming during fullscreen video.
#
# Regolith's idle daemon (regolith-powerd, through swayidle) dims the screen
# after 5 minutes, turns it off and locks, and suspends after 15. Audio
# doesn't count as activity.
#
# A user service holds a logind sleep inhibitor while audio plays, which
# refuses the idle suspend but leaves the dim, screen-off and lock alone.
#
# Regolith's sway-audio-idle-inhibit blocks every idle step while audio
# plays, the lock included, so it's masked (linked to /dev/null).
#
# Video: any fullscreen window keeps the screen on (no dim, screen-off, lock
# or suspend), as a Sway rule. It applies to windows opened after a Sway
# reload.
{ config, ... }:
let
  script = ".local/bin/audio-sleep-inhibit";
in
{
  home.file.${script} = {
    executable = true;
    source = ./files/audio-sleep-inhibit.sh;
  };

  systemd.user.services.audio-sleep-inhibit = {
    Unit = {
      Description = "Block idle suspend while audio plays";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/${script}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."regolith3/sway/config.d/60_idle".text = ''
    for_window [all] inhibit_idle fullscreen
  '';

  xdg.configFile."systemd/user/sway-audio-idle-inhibit.service".source =
    config.lib.file.mkOutOfStoreSymlink "/dev/null";
}
