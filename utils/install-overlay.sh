#!/usr/bin/env bash
#
# Clone an overlay repository into overlay/ in this repo.
#
#   utils/install-overlay.sh
#
# Asks for the overlay's GitHub repository as OWNER/REPO, and clones it from
# git@github.com:OWNER/REPO.git. The repository is private and this host may have no SSH key yet, so the
# clone uses the repository's read-only deploy key, read from the Bitwarden
# secure note REPO-deploy-key. The key only exists in a temporary directory
# for the clone. GitHub's host key is pinned, so the first connection doesn't
# have to trust whatever answers.
#
# The clone's remote stays the SSH URL: later pulls and pushes use your own
# key, once the overlay's secrets are in place.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="$root/overlay"

# shellcheck source=bitwarden.sh
source "$root/utils/bitwarden.sh"

# GitHub's published SSH host key (docs.github.com, "GitHub's SSH key
# fingerprints").
github_host_key='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'

[[ ! -e "$dest" ]] || { echo "$dest already exists" >&2; exit 1; }

read -r -p "Overlay GitHub repository (OWNER/REPO): " slug
[[ "$slug" =~ ^[A-Za-z0-9-]+/([A-Za-z0-9_.-]+)$ ]] \
  || { echo "expected OWNER/REPO" >&2; exit 1; }
repo="${BASH_REMATCH[1]%.git}"
url="git@github.com:${slug%.git}.git"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bw_unlock "read the note $repo-deploy-key"
(umask 077; bw_note "$repo-deploy-key" > "$tmp/key")
bw_lock
# ssh needs a final newline after the key; notes may lack one.
printf '\n' >> "$tmp/key"
printf '%s\n' "$github_host_key" > "$tmp/known_hosts"

GIT_SSH_COMMAND="ssh -i $tmp/key -o IdentitiesOnly=yes -o UserKnownHostsFile=$tmp/known_hosts -o StrictHostKeyChecking=yes" \
  git clone "$url" "$dest"

cat <<EOF

Installed $repo in $dest. Next:
  $root/system/setup.sh
  $root/home/setup.sh
  $root/secrets/setup.sh
then the manual steps in $dest/runbooks/.
EOF
