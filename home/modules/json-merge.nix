# Keeps chosen keys in JSON files that programs also write themselves.
#
# jsonMerge.<name> = { file; value; } merges `value` into $HOME/<file> on
# every switch and keeps everything else in it, so what the program saved
# stays. Objects merge key by key and lists are joined without duplicates.
# The file is created when missing. Keys removed from `value` stay in the
# file.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.jsonMerge;
  json = pkgs.formats.json { };
  merge = pkgs.writeText "json-merge.jq" ''
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
  options.jsonMerge = lib.mkOption {
    default = { };
    description = "JSON files with keys merged into them on every switch.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          file = lib.mkOption {
            type = lib.types.str;
            description = "Path of the file, relative to the home directory.";
          };
          value = lib.mkOption {
            type = json.type;
            default = { };
            description = "The keys to merge into the file.";
          };
        };
      }
    );
  };

  config.home.activation = lib.mapAttrs' (
    name: entry:
    lib.nameValuePair "jsonMerge-${name}" (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        file="$HOME"/${lib.escapeShellArg entry.file}
        run mkdir -p "$(dirname "$file")"
        [ -s "$file" ] || echo '{}' > "$file"
        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq -s -f ${merge} "$file" ${json.generate "${name}.json" entry.value} > "$tmp"
        run mv "$tmp" "$file"
      ''
    )
  ) cfg;
}
