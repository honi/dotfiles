#!/usr/bin/env bash
#
# Pin the overlay to the base's latest commit on GitHub, push the overlay, and
# apply the home configuration.
#
#   utils/overlay-flake-update.sh
#
# The overlay's home/flake.lock pins the base as fetched from GitHub, so only
# pushed commits can be pinned; this repo's checkout isn't read or pushed.
# When its HEAD isn't the commit pinned, that's reported: push it (or pull)
# and run this again to pin it. The overlay's flake.lock is committed if it
# changed, and pushed before the configuration applies. From a terminal, it
# ends in the new login shell.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
overlay="$root/overlay"
lock="$overlay/home/flake.lock"

warn() { printf '\033[1;33mwarning: %s\033[0m\n' "$*" >&2; }

[[ -f "$overlay/home/flake.nix" ]] || { echo "no overlay home flake in $overlay/home" >&2; exit 1; }

nix flake update dotfiles --flake "$overlay/home"
pinned="$(nix eval --raw --impure --expr \
  "let l = builtins.fromJSON (builtins.readFile $lock); in l.nodes.\${l.nodes.root.inputs.dotfiles}.locked.rev")"
short="${pinned:0:7}"

local_head="$(git -C "$root" rev-parse HEAD)"
if [[ "$local_head" != "$pinned" ]]; then
  warn "pinned $short from GitHub, but $root is at ${local_head:0:7}; push or pull it, then run this again to pin it"
fi
if [[ -n "$(git -C "$root" status --porcelain)" ]]; then
  warn "$root has uncommitted changes; they aren't part of the pin"
fi

if [[ -z "$(git -C "$overlay" status --porcelain -- home/flake.lock)" ]]; then
  echo "overlay already pins base $short"
else
  git -C "$overlay" add home/flake.lock
  git -C "$overlay" commit -m "Bump base to $short" -- home/flake.lock
fi

git -C "$overlay" push

"$root/home/setup.sh"
