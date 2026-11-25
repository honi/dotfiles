# Claude Code's configuration, with the options from claude-options.nix.
{ ... }:
{
  claude.settings = {
    # Claude Code is installed from the stable channel, so the update notice
    # checks stable too.
    autoUpdatesChannel = "stable";
    theme = "dark";
    env.ENABLE_CLAUDEAI_MCP_SERVERS = "false";
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
      "typescript-lsp@claude-plugins-official" = true;
    };
    statusLine = {
      type = "command";
      command = "~/.claude/statusline-command.sh";
      refreshInterval = 5;
    };
  };

  home.file.".claude/statusline-command.sh" = {
    source = ../files/claude-statusline.sh;
    executable = true;
  };
}
