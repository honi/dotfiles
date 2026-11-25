{ pkgs-unstable, ... }:
{
  # From nixpkgs-unstable so it always stays current.
  home.packages = [ pkgs-unstable.devenv ];

  # Enable auto activation when you cd into a directory with a devenv.nix.
  programs.bash.initExtra = ''
    eval "$(devenv hook bash -- --no-reload --no-tui)"
  '';

  # Claude Code's Bash tool runs every command in a fresh non-interactive
  # shell, so the devenv hook of interactive shells never fires. The
  # SessionStart hook has every command source this script instead.
  home.file.".claude/hooks/devenv.sh".source = ../files/claude-devenv.sh;
  claude.settings.hooks.SessionStart = [
    {
      hooks = [
        {
          type = "command";
          command = ''echo 'source "$HOME/.claude/hooks/devenv.sh"' >> "$CLAUDE_ENV_FILE"'';
        }
      ];
    }
  ];
}
