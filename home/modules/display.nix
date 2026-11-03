# Display layout: the built-in panel at native resolution, scale 1.5.
#
# Regolith applies display layouts with kanshi (user service
# regolith-init-kanshi, restarted on every Sway reload), reading
# ~/.config/regolith3/kanshi/config. A profile applies when exactly its
# outputs are connected; add a profile per monitor setup (e.g. an external
# monitor beside or instead of eDP-1).
#
# 2880x1920 at scale 1.5 gives a 1920x1280 logical desktop at full sharpness.
{ ... }:
{
  xdg.configFile."regolith3/kanshi/config".text = ''
    profile laptop {
        output eDP-1 mode 2880x1920@120Hz scale 1.5
    }
  '';
}
