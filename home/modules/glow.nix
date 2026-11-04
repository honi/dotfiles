# glow, a terminal renderer for markdown files. Installed by Nix through Home
# Manager.
{ pkgs, ... }:
{
  home.packages = [ pkgs.glow ];
}
