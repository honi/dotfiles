# Claude Code configuration. Modules add to it through two options:
#
# claude.settings: keys for ~/.claude/settings.json. Claude Code writes that
# file itself (/config, permission approvals), so instead of a read-only
# managed file, each switch merges the keys into it and keeps everything
# else. Objects merge key by key and lists are joined without duplicates, so
# entries Claude Code saved stay.
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
  managed = json.generate "claude-settings.json" cfg.settings;
  merge = pkgs.writeText "claude-settings-merge.jq" ''
    def merge($a; $b):
      if ($a | type) == "object" and ($b | type) == "object" then
        reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = merge(.[$k]; $b[$k]))
      elif ($a | type) == "array" and ($b | type) == "array" then
        $a + ($b - $a)
      else
        $b
      end;
    merge(.[0]; .[1])
  '';
in
{
  options.claude = {
    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Keys merged into ~/.claude/settings.json.";
    };
    rules = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Rule files, as the text of ~/.claude/rules/<name>.md.";
    };
  };

  config = {
    # Claude Code is installed from the stable channel, so the update notice
    # checks stable too.
    claude.settings.autoUpdatesChannel = "stable";

    home.file = lib.mapAttrs' (
      name: text: lib.nameValuePair ".claude/rules/${name}.md" { inherit text; }
    ) cfg.rules;

    home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      file="$HOME/.claude/settings.json"
      run mkdir -p "$HOME/.claude"
      [ -s "$file" ] || echo '{}' > "$file"
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq -s -f ${merge} "$file" ${managed} > "$tmp"
      run mv "$tmp" "$file"
    '';
  };
}
