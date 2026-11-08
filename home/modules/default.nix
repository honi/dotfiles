# The base user configuration. An overlay's modules are added after these.
{ ... }:
{
  imports = [
    ./appearance.nix
    ./autostart.nix
    ./bitwarden-cli.nix
    ./bluetooth.nix
    ./claude-code.nix
    ./dev.nix
    ./direnv.nix
    ./disk-space-check.nix
    ./display.nix
    ./git.nix
    ./glow.nix
    ./gnumake.nix
    ./idle.nix
    ./kbd-backlight.nix
    ./keyboard.nix
    ./lazygit.nix
    ./lock-screen.nix
    ./neovim.nix
    ./night-light.nix
    ./nix.nix
    ./playwright-cli.nix
    ./screenshots.nix
    ./session.nix
    ./shell.nix
    ./shellcheck.nix
    ./status-bar.nix
    ./suspend-check.nix
    ./tableplus.nix
    ./terminal.nix
    ./theme.nix
    ./xresources.nix
  ];

  home.username = "jb";
  home.homeDirectory = "/home/jb";

  # The Home Manager release this configuration was first written for. It
  # keeps defaults stable across upgrades; don't change it when updating.
  home.stateVersion = "26.05";

  # Start, stop and restart user services as their definitions change on
  # each switch.
  systemd.user.startServices = true;

  # No unread-news count after each switch: its hint is to run `home-manager
  # news`, and that command isn't on the PATH (it runs through the flake).
  news.display = "silent";
}
