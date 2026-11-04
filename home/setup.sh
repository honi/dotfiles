#!/usr/bin/env bash
#
# Apply the home configuration.
#
#   ./setup.sh            the overlay's configuration, or the base's without one
#   ./setup.sh --local    the same, built on the files as they are on disk
#
# With an overlay installed (cloned into overlay/ in this repo), its
# home/flake.nix is the configuration: the base at the commit its flake.lock
# pins, plus its own modules. Without one, it's this repo's base
# configuration. --local swaps the pinned base for this checkout, and reads
# both flakes straight from disk, so uncommitted and untracked files count, for
# this run only (Nix warns that it won't write that to the overlay's
# flake.lock). Files it would replace that it didn't write are kept with a
# .backup suffix. From a terminal, it ends by asking you to restart your shell,
# so the new environment applies.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

overlay="$(cd .. && pwd)/overlay/home"
use_local=false
for arg in "$@"; do
  case "$arg" in
    --local) use_local=true ;;
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
# A path: flake reads the directory as it is, where a git one skips untracked files.
if $use_local; then flake="path:$flake"; fi

nix run "$flake#home-manager" -- switch --flake "$flake#$config" -b backup "${args[@]}"

if [[ -t 0 && -t 1 ]]; then
  echo "Home configuration applied. Restart your shell to pick up the changes."
fi
