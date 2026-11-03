#!/usr/bin/env bash
#
# Add files under $HOME to the overlay's secrets, or update them there, then
# commit and push the overlay.
#
#   secrets/add.sh FILE...
#
# Each FILE is encrypted to the overlay's recipient.txt as
# secrets/files/PATH.age, PATH being FILE relative to $HOME. The result is
# decrypted again with this host's key and compared with FILE before it
# replaces the overlay's copy.
#
# Each secret gets its own commit; the first also carries any change to
# recipient.txt. Nothing else staged in the overlay is committed. The commits
# are pushed at the end; a failed push leaves them to push later.
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ $# -gt 0 ]] || { echo "usage: $0 FILE..." >&2; exit 1; }
[[ -s "$RECIPIENTS" ]] || fail "no age public key in $RECIPIENTS"
[[ -s "$KEY_FILE" ]] || fail "no age key in $KEY_FILE; run secrets/setup.sh first"
key_matches "$KEY_FILE" || fail "$KEY_FILE doesn't match $RECIPIENTS"

for file in "$@"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "$file is not a regular file"
  path="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
  [[ "$path" == "$HOME"/* ]] || fail "$file is not under $HOME"
  rel="${path#"$HOME"/}"
  out="$FILES_DIR/$rel.age"

  if [[ -e "$out" ]]; then verb="Update"; else verb="Add"; fi
  mkdir -p "$(dirname "$out")"
  tmp="$(mktemp "$out.XXXXXX")"
  age -R "$RECIPIENTS" -o "$tmp" "$path"
  if ! age -d -i "$KEY_FILE" "$tmp" | cmp -s - "$path"; then
    rm -f "$tmp"
    fail "$rel doesn't decrypt back to the same content"
  fi
  mv "$tmp" "$out"
  record_hash "$rel" "$(file_hash "$path")"

  git -C "$OVERLAY_DIR" add -- "$RECIPIENTS" "$out"
  git -C "$OVERLAY_DIR" commit -q -m "$verb secret ~/$rel" -- "$RECIPIENTS" "$out"
  echo "committed: $(git -C "$OVERLAY_DIR" log -1 --format='%h %s')"
done

if git -C "$OVERLAY_DIR" push -q; then
  echo "pushed the overlay"
else
  warn "push failed; the commits are in $OVERLAY_DIR, push them with: git -C $OVERLAY_DIR push"
fi
