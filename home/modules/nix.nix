# The user's nix.conf, which adds to the system one. It includes
# access-tokens.conf from the same directory, where a GitHub token goes
# (`access-tokens = github.com=<token>`, mode 600) so it never enters the
# Nix store. The package is only used to validate the file; nix itself is
# installed by the system. `!include` skips the file when it doesn't exist.
{ config, pkgs, ... }:
{
  nix.package = pkgs.nix;
  nix.extraOptions = ''
    !include ${config.xdg.configHome}/nix/access-tokens.conf
  '';
}
