# GNU Make, installed by Nix (not apt) through Home Manager.
{ pkgs, ... }:
{
  home.packages = [ pkgs.gnumake ];
}
