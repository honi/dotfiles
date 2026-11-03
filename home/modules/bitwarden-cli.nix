# Bitwarden CLI (`bw`) and age. Installed by Nix (not apt) through Home
# Manager: Bitwarden has no apt repository for the CLI.
#
# `bw` logs in on its own, separate from the desktop app. age encrypts and
# decrypts files with a key pair: the public key (age1...) only encrypts, the
# private key (AGE-SECRET-KEY-1...) decrypts.
{ pkgs, ... }:
{
  home.packages = [
    pkgs.bitwarden-cli
    pkgs.age
  ];
}
