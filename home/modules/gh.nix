# gh, the GitHub CLI. Installed by Nix (not apt) through Home Manager.
{ pkgs, ... }:
{
  home.packages = [ pkgs.gh ];
}
