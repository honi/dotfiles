# Lock screen styles.
#
# Regolith locks by running the command in wm.program.lock_sway, for
# Super+Escape and for swayidle (idle and before suspend). gtklock's -d runs
# it as a daemon; --style loads the stylesheet, which gtklock reads on every
# lock. Leaving out --background keeps the wallpaper off the lock screen.
# Empty time and date formats leave the clock out (the stylesheet collapses
# the empty labels).
{ config, ... }:
let
  style = "gtklock/style.css";
in
{
  xdg.configFile.${style}.source = ./files/gtklock.css;

  regolith.xresources."wm.program.lock_sway" =
    "gtklock -d --style ${config.xdg.configHome}/${style} --time-format= --date-format=";
}
