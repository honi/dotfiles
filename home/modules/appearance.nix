# Fonts, dark mode, wallpaper and window gaps.
{ lib, ... }:
{
  regolith.xresources = {
    # Fonts. Regolith applies the gtk.* values to GNOME's interface settings
    # at login, which GTK apps, dialogs, the launcher and notifications
    # follow.
    #   font_name            UI text (Roboto, from fonts-roboto)
    #   document_font_name   document body text in apps that use it
    #   monospace_font_name  monospace text in GTK apps
    #   wm.bar.font          the bar (the Nerd Font variant has the icon
    #                        glyphs the bar's material-nf icons use)
    "gtk.font_name" = "Roboto 11";
    "gtk.document_font_name" = "Roboto 11";
    "gtk.monospace_font_name" = "RobotoMono Nerd Font 11";
    "wm.bar.font" = "RobotoMono Nerd Font 11";

    # Wallpaper: a solid color. The empty file value clears the look's image;
    # #282a36 is the Dracula background.
    "regolith.wallpaper.file" = "";
    "regolith.wallpaper.color.primary" = "#282a36";

    # Gaps in pixels: inner between tiled windows, outer at the screen edges.
    # Smart gaps and smart edge borders are off so a lone window keeps both
    # its gap and its border (the defaults hide them).
    "wm.gaps.smart" = "off";
    "wm.hide.edge.borders" = "none";
    "wm.gaps.inner.size" = "8";
    "wm.gaps.outer.size" = "0";
  };

  # Dark mode. The desktop-wide color-scheme preference, read by apps that
  # pick light or dark styling themselves (libadwaita and Electron apps,
  # websites through the browser). The Dracula GTK theme is dark; this makes
  # the preference agree.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
