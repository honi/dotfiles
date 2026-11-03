# Claude Code settings. Claude Code writes ~/.claude/settings.json itself
# (/config, permission approvals), so instead of a read-only managed file,
# each switch merges the keys below into it and keeps everything else.
#
# autoUpdatesChannel: Claude Code is installed from the stable channel, so the
# update notice checks stable too.
{ lib, pkgs, ... }:
let
  settings = {
    autoUpdatesChannel = "stable";
  };
  managed = pkgs.writeText "claude-settings.json" (builtins.toJSON settings);
in
{
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    file="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    [ -s "$file" ] || echo '{}' > "$file"
    tmp="$(mktemp)"
    ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$file" ${managed} > "$tmp"
    run mv "$tmp" "$file"
  '';
}
