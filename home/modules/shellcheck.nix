# shellcheck, the linter for the shell scripts in this repo. Installed by Nix
# (not apt) through Home Manager.
{ pkgs, ... }:
{
  home.packages = [ pkgs.shellcheck ];
}
