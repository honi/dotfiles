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
# The files written, and recipient.txt, go into one commit; nothing else
# staged in the overlay does. A failed push leaves the commit to push later.
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ $# -gt 0 ]] || { echo "usage: $0 FILE..." >&2; exit 1; }
[[ -s "$RECIPIENTS" ]] || fail "no age public key in $RECIPIENTS"
[[ -s "$KEY_FILE" ]] || fail "no age key in $KEY_FILE; run secrets/setup.sh first"
key_matches "$KEY_FILE" || fail "$KEY_FILE doesn't match $RECIPIENTS"

written=()
added=()
updated=()
for file in "$@"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "$file is not a regular file"
  path="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
  [[ "$path" == "$HOME"/* ]] || fail "$file is not under $HOME"
  rel="${path#"$HOME"/}"
  out="$FILES_DIR/$rel.age"

  if [[ -e "$out" ]]; then updated+=("$rel"); else added+=("$rel"); fi
  mkdir -p "$(dirname "$out")"
  tmp="$(mktemp "$out.XXXXXX")"
  age -R "$RECIPIENTS" -o "$tmp" "$path"
  if ! age -d -i "$KEY_FILE" "$tmp" | cmp -s - "$path"; then
    rm -f "$tmp"
    fail "$rel doesn't decrypt back to the same content"
  fi
  mv "$tmp" "$out"
  record_hash "$rel" "$(file_hash "$path")"
  written+=("$out")
  echo "encrypted: ~/$rel -> ${out#"$OVERLAY_DIR"/}"
done

# commit_subject: "Add secret ~/x", "Update secrets", "Add and update secrets".
commit_subject() {
  local n=$(( ${#added[@]} + ${#updated[@]} )) verb
  if [[ ${#added[@]} -gt 0 && ${#updated[@]} -gt 0 ]]; then verb="Add and update"
  elif [[ ${#added[@]} -gt 0 ]]; then verb="Add"
  else verb="Update"
  fi
  if [[ $n -eq 1 ]]; then echo "$verb secret ~/${added[*]}${updated[*]}"
  else echo "$verb secrets"
  fi
}

message="$(commit_subject)"
if [[ $(( ${#added[@]} + ${#updated[@]} )) -gt 1 ]]; then
  message+=$'\n'
  for rel in "${added[@]}"; do message+=$'\n'"Add ~/$rel"; done
  for rel in "${updated[@]}"; do message+=$'\n'"Update ~/$rel"; done
fi

git -C "$OVERLAY_DIR" add -- "$RECIPIENTS" "${written[@]}"
git -C "$OVERLAY_DIR" commit -q -m "$message" -- "$RECIPIENTS" "${written[@]}"
echo "committed: $(git -C "$OVERLAY_DIR" log -1 --format='%h %s')"

if git -C "$OVERLAY_DIR" push -q; then
  echo "pushed the overlay"
else
  warn "push failed; the commit is in $OVERLAY_DIR, push it with: git -C $OVERLAY_DIR push"
fi
