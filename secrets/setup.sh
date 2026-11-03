#!/usr/bin/env bash
#
# Decrypt the overlay's secrets into $HOME.
#
#   secrets/setup.sh
#
# Each secrets/files/PATH.age in the overlay is decrypted to $HOME/PATH, as a
# plain file only you can read (0600; new directories 0700). Only files whose
# content differs are written.
#
# The age private key is ~/.config/age/key.txt. When it's missing, it's read
# from the Bitwarden secure note REPO-age-key, REPO being the overlay's
# repository name, and checked against the overlay's recipient.txt.
#
# A file in $HOME that changed since it was last written here (an app edited
# it, or you did) is left as it is, with a warning: save it into the overlay
# with secrets/add.sh, or delete it and run this again to restore the
# overlay's version. The same goes for a file that already existed with
# different content before its first decrypt.
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [[ ! -d "$FILES_DIR" ]]; then
  echo "no overlay secrets in $FILES_DIR; nothing to do"
  exit 0
fi
[[ -s "$RECIPIENTS" ]] || fail "no age public key in $RECIPIENTS"

if [[ ! -s "$KEY_FILE" ]]; then
  # shellcheck source=../utils/bitwarden.sh
  source "$ROOT_DIR/utils/bitwarden.sh"
  repo="$(basename "$(git -C "$OVERLAY_DIR" remote get-url origin)" .git)"
  install -d -m 0700 "$(dirname "$KEY_FILE")"
  tmp="$(mktemp "$KEY_FILE.XXXXXX")"
  trap 'rm -f "$tmp"' EXIT
  bw_unlock
  bw_note "$repo-age-key" > "$tmp"
  bw_lock
  key_matches "$tmp" || fail "the note $repo-age-key doesn't match $RECIPIENTS"
  mv "$tmp" "$KEY_FILE"
  echo "wrote $KEY_FILE from $repo-age-key"
fi
key_matches "$KEY_FILE" || fail "$KEY_FILE doesn't match $RECIPIENTS"

umask 077
kept=()
while IFS= read -r -d '' enc; do
  rel="${enc#"$FILES_DIR"/}"
  rel="${rel%.age}"
  target="$HOME/$rel"
  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp "$target.XXXXXX")"
  age -d -i "$KEY_FILE" -o "$tmp" "$enc" || { rm -f "$tmp"; fail "can't decrypt $enc"; }
  new="$(file_hash "$tmp")"

  if [[ -e "$target" ]]; then
    current="$(file_hash "$target")"
    if [[ "$current" == "$new" ]]; then
      rm -f "$tmp"
      record_hash "$rel" "$new"
      echo "unchanged: ~/$rel"
      continue
    fi
    if [[ "$current" != "$(recorded_hash "$rel")" ]]; then
      rm -f "$tmp"
      warn "$HOME/$rel differs from the overlay and was changed here; kept"
      kept+=("$rel")
      continue
    fi
  fi

  chmod 0600 "$tmp"
  mv "$tmp" "$target"
  record_hash "$rel" "$new"
  echo "wrote: ~/$rel"
done < <(find "$FILES_DIR" -type f -name '*.age' -print0 | sort -z)

# Every secret is in place: written now, unchanged, or kept with a warning.
missing=0
while IFS= read -r -d '' enc; do
  rel="${enc#"$FILES_DIR"/}"
  rel="${rel%.age}"
  if [[ ! -f "$HOME/$rel" ]]; then warn "$HOME/$rel missing"; missing=1; fi
done < <(find "$FILES_DIR" -type f -name '*.age' -print0)
[[ $missing -eq 0 ]] || fail "some secrets are missing"

if [[ ${#kept[@]} -gt 0 ]]; then
  echo "kept local changes (secrets/add.sh saves them into the overlay):"
  printf '  ~/%s\n' "${kept[@]}"
fi
