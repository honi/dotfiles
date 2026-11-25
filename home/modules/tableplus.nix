# TablePlus: always light, in Roboto Mono.
#
# The window chrome follows the system GTK theme, so a wrapper in
# ~/.local/bin starts TablePlus with the light Adwaita theme whatever the
# system theme is. The launcher and the terminal both use it.
#
# TablePlus writes ~/.tableplus/settings/settings.json itself (window layout,
# preferences), so each switch merges the keys below into it. TablePlus
# rewrites the file on quit, so a change made while it is running applies
# after it is restarted.
{ config, ... }:
let
  font = "RobotoMono Nerd Font";
  settings = {
    theme-id = "Light";
    editor-font-family = font;
    editor-font-face = "Regular";
    data-table-font-family = font;
    data-table-font-face = "Regular";
    console-font-family = font;
    console-font-face = "Regular";
    disable-auto-uppercase-keyword = true;
    disable-wrap-lines-to-editor-width = 1;
  };
in
{
  home.file.".local/bin/tableplus" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      GTK_THEME=Adwaita exec /usr/local/bin/tableplus "$@"
    '';
  };

  xdg.dataFile."applications/tableplus.desktop".text = ''
    [Desktop Entry]
    Name=TablePlus
    Type=Application
    Exec=${config.home.homeDirectory}/.local/bin/tableplus %u
    Icon=/opt/tableplus/resource/image/logo.png
    Categories=Development
    MimeType=x-scheme-handler/tableplus;
    Terminal=false
  '';

  jsonMerge.tableplus = {
    file = ".tableplus/settings/settings.json";
    value = settings;
  };
}
