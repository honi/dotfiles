# Claude Code's configuration, with the options from claude-options.nix.
{ ... }:
{
  claude.settings = {
    # Claude Code is installed from the stable channel, so the update notice
    # checks stable too.
    autoUpdatesChannel = "stable";
    theme = "dark-ansi";
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

  claude.mcpServers.atlassian = {
    type = "http";
    url = "https://mcp.atlassian.com/v2/mcp";
  };

  home.file.".claude/statusline-command.sh" = {
    source = ../files/claude-statusline.sh;
    executable = true;
  };
}
