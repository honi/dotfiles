# Keyboard backlight: off while idle and asleep.
#
# A user service runs its own swayidle, which turns the backlight off after
# 5 minutes without input (the screen dim time) and before sleep, and brings
# it back on activity and after resume. Like any swayidle, it holds back
# while a window is fullscreen. Stopping the service (logout, shutdown)
# brings the backlight back too, so the next boot starts with the light as
# it was.
#
# The device is group video, so no root access is needed.
{ config, ... }:
let
  script = ".local/bin/kbd-backlight";
  kbd = "${config.home.homeDirectory}/${script}";
in
{
  home.file.${script} = {
    executable = true;
    source = ../files/kbd-backlight.sh;
  };

  systemd.user.services.kbd-backlight = {
    Unit = {
      Description = "Keyboard backlight off while idle and asleep";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "swayidle -w timeout 300 '${kbd} off' resume '${kbd} on' before-sleep '${kbd} off' after-resume '${kbd} on'";
      ExecStopPost = "${kbd} on";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
