# Zoom, from Zoom's .deb (Zoom has no apt repository).
#
# zoom.us/client/latest/zoom_amd64.deb redirects to a URL that names the
# current version, which matches the package's own version. The step reads it
# from the redirect and downloads only when the installed version differs, so
# running the step again updates Zoom (it doesn't update itself on Linux).
#
# The .deb is installed through apt, from /tmp (apt reads local packages as
# its _apt user), so its dependencies come along.

url=https://zoom.us/client/latest/zoom_amd64.deb

# wget exits non-zero on the redirect it's told not to follow.
location="$( (wget --max-redirect=0 -S --spider "$url" 2>&1 || true) | awk 'tolower($1) == "location:" {print $2; exit}')"
latest="$(sed -n 's|.*/prod/\([0-9.]*\)/zoom_amd64\.deb$|\1|p' <<<"$location")"
[[ -n "$latest" ]] || fail "no Zoom version in the redirect from $url (got: ${location:-nothing})"
installed="$(dpkg-query -W -f='${Version}' zoom 2>/dev/null || true)"

if [[ "$installed" == "$latest" ]]; then
  log "already installed: zoom $installed"
else
  log "installing zoom $latest${installed:+ (was $installed)}"
  wget -qO /tmp/zoom_amd64.deb "$location"
  apt-get install -y -q /tmp/zoom_amd64.deb
  rm -f /tmp/zoom_amd64.deb
fi

verify_installed zoom
verify "zoom $latest installed" test "$(dpkg-query -W -f='${Version}' zoom)" = "$latest"
