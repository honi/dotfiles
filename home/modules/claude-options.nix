# The options modules use to configure Claude Code:
#
# claude.settings: keys for ~/.claude/settings.json. Claude Code writes that
# file itself (/config, permission approvals), so they are merged into it
# rather than installed as a read-only file.
#
# claude.mcpServers.<name>: user-scope MCP servers, merged into the
# mcpServers key of ~/.claude.json. Claude Code keeps its own state in that
# file, so only the servers declared here are touched.
#
# claude.rules.<name>: the text of ~/.claude/rules/<name>.md, a rule Claude
# Code loads in every session.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.claude;
  json = pkgs.formats.json { };
in
{
  options.claude = {
    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Keys merged into ~/.claude/settings.json.";
    };
    mcpServers = lib.mkOption {
      type = json.type;
      default = { };
      description = "User-scope MCP servers, as in the mcpServers key of ~/.claude.json.";
    };
    rules = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Rule files, as the text of ~/.claude/rules/<name>.md.";
    };
  };

  config = {
    jsonMerge.claude-settings = {
      file = ".claude/settings.json";
      value = cfg.settings;
    };

    jsonMerge.claude-mcp = {
      file = ".claude.json";
      value.mcpServers = cfg.mcpServers;
    };

    home.file = lib.mapAttrs' (
      name: text: lib.nameValuePair ".claude/rules/${name}.md" { inherit text; }
    ) cfg.rules;
  };
}
