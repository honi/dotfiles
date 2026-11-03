# shellcheck shell=bash
# Paths and helpers shared by setup.sh and add.sh.
#
# The overlay keeps its secrets in secrets/: recipient.txt holds the age
# public key (or keys, one per line) that new secrets are encrypted to, and
# files/PATH.age is the encrypted copy of $HOME/PATH. The private key that
# decrypts them lives in KEY_FILE.
#
# STATE_DIR records the hash of each secret as last written or added, so
# setup.sh can tell a file changed in $HOME from one that changed in the
# overlay.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY_DIR="$ROOT_DIR/overlay"
SECRETS_DIR="$OVERLAY_DIR/secrets"
RECIPIENTS="$SECRETS_DIR/recipient.txt"
FILES_DIR="$SECRETS_DIR/files"
KEY_FILE="$HOME/.config/age/key.txt"
STATE_DIR="$HOME/.local/state/dotfiles/secrets"

warn() { printf '\033[1;33mwarning: %s\033[0m\n' "$*" >&2; }
fail() { printf '\033[1;31mfailed: %s\033[0m\n' "$*" >&2; exit 1; }

file_hash() { sha256sum "$1" | cut -d' ' -f1; }

# key_matches KEY: KEY's public key is one of the overlay's recipients.
key_matches() {
  local public
  public="$(age-keygen -y "$1")" || return 1
  grep -qxF "$public" "$RECIPIENTS"
}

# record_hash REL HASH: remember the content last written or added for REL.
record_hash() {
  install -d -m 0700 "$(dirname "$STATE_DIR/$1")"
  printf '%s\n' "$2" > "$STATE_DIR/$1.sha256"
}
recorded_hash() { cat "$STATE_DIR/$1.sha256" 2>/dev/null || true; }
