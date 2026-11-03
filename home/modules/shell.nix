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

    # Prompt: the hostname and the last three directories in grey, as
    # host:dir, then in a git repository "(branch)", then a Dracula purple
    # (#bd93f9) ">". The branch is yellow while files are changed or
    # untracked, and carries "+N" for commits not pushed and "-N" for commits
    # not pulled, as of the last fetch (the prompt never touches the network).
    # PROMPT_DIRTRIM keeps \w to three components (the rest shows as "...").
    # The terminal title is set to user@host: dir.
    initExtra = ''
      PROMPT_DIRTRIM=3
      __set_prompt() {
        local grey='\[\e[38;5;245m\]' yellow='\[\e[33m\]' purple='\[\e[38;2;189;147;249m\]'
        local reset='\[\e[0m\]' title= branch= ahead= behind= dirty= line= git= counts= color=
        case "$TERM" in
          xterm*|rxvt*|foot*) title='\[\e]0;\u@\h: \w\a\]' ;;
        esac
        while read -r line; do
          case "$line" in
            "# branch.head "*) branch=''${line#\# branch.head } ;;
            "# branch.ab "*) read -r ahead behind <<< "''${line#\# branch.ab }" ;;
            "#"*) ;;
            *) dirty=1 ;;
          esac
        done < <(GIT_OPTIONAL_LOCKS=0 git status --porcelain=v2 --branch 2>/dev/null)
        if [ -n "$branch" ]; then
          [ "$branch" = "(detached)" ] && branch=$(git rev-parse --short HEAD 2>/dev/null)
          [ -n "$ahead" ] && [ "$ahead" != "+0" ] && counts=$ahead
          [ -n "$behind" ] && [ "$behind" != "-0" ] && counts="$counts''${counts:+/}$behind"
          color=$grey
          [ -n "$dirty" ] && color=$yellow
          git=" $color($branch''${counts:+ $counts})$reset"
        fi
        PS1="$title$grey\h:\w$reset$git $purple>$reset "
      }
      PROMPT_COMMAND="__set_prompt''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
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
