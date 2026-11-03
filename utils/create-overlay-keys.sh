#!/usr/bin/env bash
#
# Generate a new overlay's two keys and print each with where it goes.
#
#   utils/create-overlay-keys.sh
#
# Asks for the overlay's GitHub repository as OWNER/REPO, then prints:
#   - the deploy key's public half, for the repository's deploy keys;
#   - the deploy key, for the Bitwarden secure note REPO-deploy-key;
#   - the age key, for the Bitwarden secure note REPO-age-key;
#   - the age public key, for the overlay's secrets/recipient.txt.
#
# Nothing is stored: the deploy key only exists in a temporary directory
# while it's printed, and the age key only in memory.
set -euo pipefail

for cmd in ssh-keygen age-keygen; do
  command -v "$cmd" >/dev/null || { echo "$cmd not found" >&2; exit 1; }
done

read -r -p "Overlay GitHub repository (OWNER/REPO): " slug
[[ "$slug" =~ ^[A-Za-z0-9-]+/([A-Za-z0-9_.-]+)$ ]] \
  || { echo "expected OWNER/REPO" >&2; exit 1; }
slug="${slug%.git}"
repo="${BASH_REMATCH[1]%.git}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

ssh-keygen -q -t ed25519 -N '' -C "$repo-deploy-key" -f "$tmp/key"

# age-keygen writes the key to stdout, with the public key on a
# "# public key: age1…" comment line.
age_key="$(age-keygen 2>/dev/null)"
age_public="$(sed -n 's/^# public key: \(age1[0-9a-z]*\)$/\1/p' <<<"$age_key")"
[[ -n "$age_public" ]] || { echo "no public key in age-keygen's output" >&2; exit 1; }

header() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

header "GitHub → $slug → Settings → Deploy keys → Add deploy key, write access off:"
cat "$tmp/key.pub"

header "Bitwarden: new secure note $repo-deploy-key, the whole key as its content:"
cat "$tmp/key"

header "Bitwarden: new secure note $repo-age-key, the whole key as its content:"
printf '%s\n' "$age_key"

header "The overlay's secrets/recipient.txt, then commit it:"
printf '%s\n' "$age_public"
