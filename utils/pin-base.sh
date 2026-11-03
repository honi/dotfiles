#!/usr/bin/env bash
#
# Pin the overlay to this repo's current commit, apply the home
# configuration, and push the overlay.
#
#   utils/pin-base.sh
#
# The overlay's home/flake.lock pins the base at a commit on GitHub, so the
# commit has to be pushed first: this refuses uncommitted changes, pushes,
# updates the overlay's dotfiles input to the pushed commit, and commits the
# overlay's flake.lock if it changed. The overlay is pushed only once the
# configuration applies, so a pin that fails never leaves this install.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
overlay="$root/overlay"

[[ -f "$overlay/home/flake.nix" ]] || { echo "no overlay home flake in $overlay/home" >&2; exit 1; }
[[ -z "$(git -C "$root" status --porcelain)" ]] || { echo "$root has uncommitted changes; commit them first" >&2; exit 1; }

git -C "$root" push
commit="$(git -C "$root" rev-parse --short HEAD)"

nix flake update dotfiles --flake "$overlay/home"

if [[ -z "$(git -C "$overlay" status --porcelain -- home/flake.lock)" ]]; then
  echo "overlay already pins base $commit"
else
  git -C "$overlay" add home/flake.lock
  git -C "$overlay" commit -m "Pin base $commit" -- home/flake.lock
fi

"$root/home/setup.sh"

git -C "$overlay" push
