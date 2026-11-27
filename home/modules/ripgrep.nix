# ripgrep (`rg`), the fast recursive text search.
{ pkgs, ... }:
{
  home.packages = [ pkgs.ripgrep ];
}
