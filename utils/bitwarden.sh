# shellcheck shell=bash
# Bitwarden CLI helpers, sourced by the scripts that read keys from the vault.
#
#   bw_unlock   logs in (email, master password, two-step code) or unlocks,
#               as needed. bw asks on stderr, so only the session token is
#               captured; it stays in an unexported variable and is passed
#               only to bw's own environment.
#   bw_note N   prints the secure note named N; fails unless exactly one
#               item has that name.
#   bw_lock     locks the vault again.

BW_SESSION_TOKEN=""

bw_unlock() {
  local status
  command -v bw >/dev/null || { echo "bw not found; run home/setup.sh first" >&2; return 1; }
  status="$(bw status | jq -r .status)"
  case "$status" in
    unauthenticated) BW_SESSION_TOKEN="$(bw login --raw)" ;;
    locked)          BW_SESSION_TOKEN="$(bw unlock --raw)" ;;
    unlocked)        BW_SESSION_TOKEN="${BW_SESSION:-}" ;;
    *)               echo "unexpected bw status: $status" >&2; return 1 ;;
  esac
  [[ -n "$BW_SESSION_TOKEN" ]] || { echo "no Bitwarden session" >&2; return 1; }
  BW_SESSION="$BW_SESSION_TOKEN" bw sync >/dev/null
}

bw_note() {
  BW_SESSION="$BW_SESSION_TOKEN" bw get notes "$1"
}

bw_lock() {
  bw lock >/dev/null
  BW_SESSION_TOKEN=""
}
