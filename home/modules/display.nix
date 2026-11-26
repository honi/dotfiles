# Display layout: scale 1.5 on every screen.
#
# Regolith applies display layouts with kanshi (user service
# regolith-init-kanshi, restarted on every Sway reload), reading
# ~/.config/regolith3/kanshi/config. A profile applies when exactly its
# outputs are connected; add a profile per monitor setup.
#
# The built-in panel runs at native 2880x1920, which at scale 1.5 is a
# 1920x1280 logical desktop at full sharpness. Docked, the 4K monitor is the
# main screen at 120Hz (2560x1440 logical) with the laptop panel to its left,
# bottom-aligned (1440 - 1280 = 160). The monitor is matched by make, model
# and serial, so any port or cable works; kanshi has no wildcards.
#
# Regolith's clamshell binding reacts only to lid changes, and it holds the
# lid-switch inhibitor, so logind never acts on the lid. A profile applied
# with the lid already closed therefore needs its own handling: the docked
# profile turns the hidden panel off, and the laptop profile (no monitor left,
# so nothing to work on) suspends.
#
# Workspaces 1-19 are assigned to the monitor with eDP-1 as fallback: Sway
# moves them to the monitor on plug-in and back on unplug. A rule applies when
# a workspace is created under its plain name ("1"); Regolith adds the icons
# to the name afterwards, and the workspace keeps its output priority.
{ lib, ... }:
let
  monitor = "Dell Inc. DELL U3225QE HYRT784";
  workspaces = lib.range 1 19;
in
{
  xdg.configFile."regolith3/kanshi/config".text = ''
    profile laptop {
        output eDP-1 mode 2880x1920@120Hz scale 1.5
        exec grep -q closed /proc/acpi/button/lid/LID0/state && systemctl suspend
    }

    profile docked {
        output "${monitor}" mode 3840x2160@120Hz scale 1.5 position 1920,0
        output eDP-1 mode 2880x1920@120Hz scale 1.5 position 0,160
        exec grep -q closed /proc/acpi/button/lid/LID0/state && swaymsg output eDP-1 disable
    }
  '';

  xdg.configFile."regolith3/sway/config.d/60_workspaces".text = lib.concatMapStrings (
    n: "workspace ${toString n} output \"${monitor}\" eDP-1\n"
  ) workspaces;
}
