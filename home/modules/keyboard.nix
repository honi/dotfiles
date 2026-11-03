# Keyboard: layout and key repeat.
{ lib, ... }:
{
  # Layout. regolith-inputd applies keyboard settings to Sway and reads the
  # layout from GNOME's input-sources list; an empty list (a fresh account)
  # makes it fail. Each entry is a (type, layout) pair; xkb "us" is the US
  # layout.
  dconf.settings."org/gnome/desktop/input-sources".sources = [
    (lib.hm.gvariant.mkTuple [
      "xkb"
      "us"
    ])
  ];

  # Key repeat, as a Sway snippet. Regolith includes every file in
  # ~/.config/regolith3/sway/config.d; they apply on a Sway reload.
  #   repeat_delay  ms a key is held before it starts repeating
  #   repeat_rate   repeats per second after that
  xdg.configFile."regolith3/sway/config.d/60_keyboard".text = ''
    input type:keyboard {
        repeat_delay 200
        repeat_rate 60
    }
  '';
}
