# bash: ~/.bashrc and ~/.profile with Debian's stock behavior (history,
# colored ls, completion), a minimal prompt and the PATH for Nix programs
# and user scripts.
{ ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;
    shellOptions = [
      "histappend"
      "checkwinsize"
    ];

    # Terminals started without a login shell skip ~/.profile, so source the
    # session variables here too (the file guards against running twice).
    bashrcExtra = ''
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';

    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -alhF";
    };

    # Prompt: the last three directories in grey, then a Dracula purple
    # (#bd93f9) ">". PROMPT_DIRTRIM keeps \w to three components (the rest
    # shows as "..."). The terminal title is set to user@host: dir.
    initExtra = ''
      PROMPT_DIRTRIM=3
      PS1='\[\e[38;5;245m\]\w\[\e[0m\] \[\e[38;2;189;147;249m\]>\[\e[0m\] '
      case "$TERM" in
        xterm*|rxvt*|foot*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
      esac
    '';
  };

  # Sort by byte (ls, globs, sort), so dotfiles group first and uppercase
  # names come before lowercase; en_US ignores the leading dot.
  home.sessionVariables.LC_COLLATE = "C";

  # Nix-installed programs (Home Manager's profile) and user scripts, added
  # by every login shell. Not home.sessionPath: greetd sources ~/.profile
  # before the session, then gnome-session starts a second login shell whose
  # /etc/profile resets PATH, and Home Manager's session variables file
  # (guarded to run once) would skip re-adding them. Terminals inherit PATH
  # from the session.
  programs.bash.profileExtra = ''
    for dir in "$HOME/.local/bin" "$HOME/.nix-profile/bin"; do
      case ":$PATH:" in
        *":$dir:"*) ;;
        *) PATH="$dir:$PATH" ;;
      esac
    done
    export PATH
  '';

  # The same for the systemd user manager (environment.d), so the Sway
  # session, the programs it starts and user services find Nix programs by
  # name. Read at login.
  systemd.user.sessionVariables.PATH = "$HOME/.nix-profile/bin:$PATH";

  # Likewise for desktop entries, so the app launcher lists Nix-installed
  # apps. Spelled out with the Debian defaults because XDG_DATA_DIRS is unset
  # in environment.d.
  systemd.user.sessionVariables.XDG_DATA_DIRS = "$HOME/.nix-profile/share:/usr/local/share:/usr/share";
}
