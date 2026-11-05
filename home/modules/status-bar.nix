# The bar: status blocks, position and tray menu colors.
#
# Regolith's bar runs i3status-rust with the file named by
# wm.bar.status_config. Edits to the TOML apply on a Sway reload
# (Super+Shift+R); the Xresources settings apply at the next login.
# Regolith has no setting for the bar's margin, so a Sway snippet adds it.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  statusConfig = "regolith3/i3status-rust/config.toml";
in
{
  options.statusBar = {
    vpn = lib.mkEnableOption "the VPN block, which runs ~/.local/bin/vpn (status and toggle); the overlay provides that script";
    hostBg = lib.mkOption {
      type = lib.types.str;
      default = "#bd93f9";
      description = "Background of the hostname block, to tell machines apart (Dracula purple by default).";
    };
    hostFg = lib.mkOption {
      type = lib.types.str;
      default = "#282a36";
      description = "Text color of the hostname block (Dracula background by default).";
    };
  };

  config = {
    xdg.configFile.${statusConfig}.source = pkgs.replaceVars ../files/i3status-rust.toml {
      inherit (config.statusBar) hostBg hostFg;
      vpnBlock = lib.optionalString config.statusBar.vpn (
        builtins.readFile ../files/i3status-rust-vpn.toml
      );
    };

    # Margin around the bar (top right bottom left), matching the inner window
    # gap so the workspace buttons line up with the windows below. Regolith's
    # bar is Sway's first, bar-0; the snippet loads after Regolith's bar block.
    #
    # tray_padding spaces the tray icons and pads their menu items. It counts
    # buffer pixels: at scale 1.5 swaybar draws at 2x, so 8 gives 4 logical
    # pixels. Icons get the bar height minus the padding on both sides, and
    # swaybar only scales them by whole multiples; a height of 32 leaves a
    # 48 px slot, which fits 22 px and 24 px icons at 2x.
    xdg.configFile."regolith3/sway/config.d/71_bar_gaps".text = ''
      bar bar-0 gaps 8 8 0 8
      bar bar-0 tray_padding 8
      bar bar-0 height 32
    '';

    regolith.xresources = {
      "wm.bar.status_config" = "${config.xdg.configHome}/${statusConfig}";

      # Bar at the top of the screen. The tray always sits at its far right.
      "wm.bar.position" = "top";

      # Background: Dracula's #282a36 darkened by 50%.
      "wm.bar.background.color" = "#14151b";

      # Regolith's Sway draws tray menus itself, with the bar's background color
      # and its statusline color for the text. The Dracula look sets statusline
      # to a dark shade (unused on the bar itself, since i3status-rust colors
      # its blocks), which makes menu text dark on dark. Dracula's foreground
      # fixes it.
      "wm.bar.statusline.color" = "#f8f8f2";
    };
  };
}
