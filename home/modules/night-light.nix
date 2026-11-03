# Night light: warmer screen colors at night.
#
# GNOME's Night Light (the switch in Regolith's control center) does nothing
# here: gsd-color applies it through GNOME's compositor, which Sway isn't.
# wlsunset sets the colors through Sway's gamma control instead, on the same
# schedule as the GNOME settings (20:00 to 06:00), at 4600 K: halfway between
# GNOME's 2700 K and neutral 6500 K, for half the tint.
# It runs as a user service with the graphical session.
#
# The change fades in over 30 minutes instead of switching at once. Home
# Manager has no option for wlsunset's -d (transition duration), so the
# command is written out here from the settings above.
{ config, lib, ... }:
let
  cfg = config.services.wlsunset;
  fadeSeconds = 1800;
in
{
  services.wlsunset = {
    enable = true;
    sunset = "20:00";
    sunrise = "06:00";
    temperature.night = 4600;
  };

  systemd.user.services.wlsunset.Service.ExecStart = lib.mkForce (
    lib.concatStringsSep " " [
      "${cfg.package}/bin/wlsunset"
      "-s ${cfg.sunset}"
      "-S ${cfg.sunrise}"
      "-t ${toString cfg.temperature.night}"
      "-T ${toString cfg.temperature.day}"
      "-d ${toString fadeSeconds}"
    ]
  );
}
