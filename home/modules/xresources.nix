# Regolith's per-user settings file: ~/.config/regolith3/Xresources.
#
# Regolith reads its settings (fonts, colors, bar, programs, gaps) as
# Xresources-style `name: value` lines. The look (Dracula) supplies defaults
# under /usr/share/regolith-look; this file overrides individual names.
# Regolith loads it at login, so changes apply after logging out and back in.
#
# Other modules add their settings to `regolith.xresources`; this module
# writes them all, sorted by name, into the one file.
{ config, lib, ... }:
let
  cfg = config.regolith.xresources;
  line = name: value: if value == "" then "${name}:" else "${name}: ${value}";
in
{
  options.regolith.xresources = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Regolith Xresources settings (name = value).";
  };

  config.xdg.configFile."regolith3/Xresources".text =
    lib.concatStringsSep "\n" (lib.mapAttrsToList line cfg) + "\n";
}
