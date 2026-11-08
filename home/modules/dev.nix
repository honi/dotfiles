{ pkgs-unstable, ... }:
{
  # From nixpkgs-unstable so it always stays current.
  home.packages = [ pkgs-unstable.devenv ];

  # Enable auto activation when you cd into a directory with a devenv.nix.
  programs.bash.initExtra = ''
    eval "$(devenv hook bash -- --no-reload)"
  '';
}
