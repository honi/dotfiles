#!/usr/bin/env bash
#
# Add files under $HOME to the overlay's secrets, or update them there.
#
#   secrets/add.sh FILE...
#
# Each FILE is encrypted to the overlay's recipient.txt as
# secrets/files/PATH.age, PATH being FILE relative to $HOME. The result is
# decrypted again with this install's key and compared with FILE before it
# replaces the overlay's copy. Commit the overlay afterwards.
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

  mkdir -p "$(dirname "$out")"
  tmp="$(mktemp "$out.XXXXXX")"
  age -R "$RECIPIENTS" -o "$tmp" "$path"
  if ! age -d -i "$KEY_FILE" "$tmp" | cmp -s - "$path"; then
    rm -f "$tmp"
    fail "$rel doesn't decrypt back to the same content"
  fi
  mv "$tmp" "$out"
  record_hash "$rel" "$(file_hash "$path")"
  echo "added: ~/$rel -> ${out#"$OVERLAY_DIR"/}"
done

echo "commit the overlay: git -C $OVERLAY_DIR add secrets && git -C $OVERLAY_DIR commit"
