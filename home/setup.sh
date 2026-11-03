#!/usr/bin/env bash
#
# Apply the home configuration.
#
#   ./setup.sh            the overlay's configuration, or the base's without one
#   ./setup.sh --local    the overlay's, built on this repo as it is on disk
#   ./setup.sh --no-shell don't end with a login shell (for scripts)
#
# With an overlay installed (cloned into overlay/ in this repo), its
# home/flake.nix is the configuration: the base at the commit its flake.lock
# pins, plus its own modules. Without one, it's this repo's base
# configuration. --local swaps the pinned base for this checkout, committed or
# not, for this run only (Nix warns that it won't write that to the overlay's
# flake.lock). Files it would replace that it didn't write are kept with a
# .backup suffix. From a terminal, it ends by replacing itself with a login
# shell, the configured one, in the directory it was run from, so the new
# environment applies.
set -euo pipefail
start_dir="$PWD"
cd "$(dirname "${BASH_SOURCE[0]}")"

overlay="$(cd .. && pwd)/overlay/home"
use_local=false
shell=true
for arg in "$@"; do
  case "$arg" in
    --local) use_local=true ;;
    --no-shell) shell=false ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

args=()
if [[ -f "$overlay/flake.nix" ]]; then
  flake="$overlay"
  config=default
  if $use_local; then args+=(--override-input dotfiles "path:$PWD"); fi
else
  flake="$PWD"
  config=base
fi

nix run "$flake#home-manager" -- switch --flake "$flake#$config" -b backup "${args[@]}"

if $shell && [[ -t 0 && -t 1 ]]; then
  cd "$start_dir"
  exec nix run "$flake#homeConfigurations.$config.config.programs.bash.package" -- -l
fi
