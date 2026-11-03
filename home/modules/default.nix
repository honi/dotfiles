# The base user configuration. An overlay's modules are added after these.
{ ... }:
{
  imports = [
    ./xresources.nix
    ./appearance.nix
    ./status-bar.nix
    ./display.nix
    ./night-light.nix
    ./keyboard.nix
    ./lock-screen.nix
    ./idle.nix
    ./session.nix
    ./screenshots.nix
    ./terminal.nix
    ./shell.nix
    ./git.nix
    ./lazygit.nix
    ./neovim.nix
    ./direnv.nix
    ./disk-space-check.nix
    ./suspend-check.nix
    ./autostart.nix
    ./bluetooth.nix
    ./claude-code.nix
    ./bitwarden-cli.nix
  ];

  home.username = "jb";
  home.homeDirectory = "/home/jb";

  # The Home Manager release this configuration was first written for. It
  # keeps defaults stable across upgrades; don't change it when updating.
  home.stateVersion = "26.05";

  # Start, stop and restart user services as their definitions change on
  # each switch.
  systemd.user.startServices = true;
}
