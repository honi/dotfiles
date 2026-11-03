# Bitwarden desktop app, from Bitwarden's .deb (Bitwarden has no apt
# repository).
#
# bitwarden.com's download link redirects to the .deb of the current release
# on GitHub (bitwarden/clients), in a URL that names the version, which
# matches the package's own version. The step reads it from the redirect,
# only accepts a redirect to that repository's desktop release, and downloads
# only when the installed version differs, so running the step again updates
# Bitwarden.
#
# Bitwarden doesn't sign the .deb. The download is checked against the
# SHA-256 digest GitHub's API reports for the release asset, fetched in a
# separate request from the download. That catches a download that was
# corrupted or swapped on the way, not a release published by someone with
# write access to Bitwarden's repository.
#
# The .deb is installed through apt, from a directory apt's _apt user can
# read, so its dependencies come along.

url='https://bitwarden.com/download/?app=desktop&platform=linux&variant=deb'
release_re='^https://github\.com/bitwarden/clients/releases/download/desktop-v([0-9.]+)/Bitwarden-([0-9.]+)-amd64\.deb$'

apt_install jq

# wget exits non-zero on the redirect it's told not to follow.
location="$( (wget --max-redirect=0 -S --spider "$url" 2>&1 || true) | awk 'tolower($1) == "location:" {print $2; exit}' | tr -d '\r')"
[[ "$location" =~ $release_re && "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" ]] \
  || fail "unexpected redirect from $url (got: ${location:-nothing})"
latest="${BASH_REMATCH[1]}"
installed=""
if is_installed bitwarden; then installed="$(dpkg-query -W -f='${Version}' bitwarden)"; fi

if [[ "$installed" == "$latest" ]]; then
  log "already installed: bitwarden $installed"
else
  log "installing bitwarden $latest${installed:+ (was $installed)}"
  asset="${location##*/}"
  digest="$(wget -qO- "https://api.github.com/repos/bitwarden/clients/releases/tags/desktop-v$latest" \
    | jq -r --arg name "$asset" '.assets[] | select(.name == $name) | .digest // empty')"
  [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || fail "no SHA-256 digest for $asset in GitHub's API (got: ${digest:-nothing})"

  tmp="$(mktemp -d)"
  chmod 0755 "$tmp"
  wget -qO "$tmp/$asset" "$location"
  if ! sha256sum --quiet -c - <<<"${digest#sha256:}  $tmp/$asset"; then
    rm -rf "$tmp"
    fail "$asset doesn't match GitHub's digest $digest"
  fi
  log "verified: $asset matches $digest"
  chmod 0644 "$tmp/$asset"
  apt-get install -y -q "$tmp/$asset"
  rm -rf "$tmp"
fi

verify_installed bitwarden
verify "bitwarden $latest installed" test "$(dpkg-query -W -f='${Version}' bitwarden)" = "$latest"
verify "bitwarden on PATH" command -v bitwarden
