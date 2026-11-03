# direnv, which loads and unloads environment variables from a directory's
# .envrc as you cd in and out. Installed by Nix (not apt) through Home
# Manager, which also hooks it into bash. nix-direnv caches `use flake` and
# `use nix` environments so they don't rebuild on every cd.
{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
