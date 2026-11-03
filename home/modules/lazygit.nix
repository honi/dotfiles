# lazygit, the terminal UI for git. Installed by Nix (not apt) through Home
# Manager, which also manages its config file.
{ ... }:
{
  programs.lazygit.enable = true;
}
