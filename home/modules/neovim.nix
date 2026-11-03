# Neovim, the text editor. Installed by Nix (not apt) through Home Manager,
# which also makes it the default editor (EDITOR) and adds vi and vim aliases.
{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
