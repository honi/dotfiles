# Docker Engine from Docker's apt repository, as Docker's Debian install guide
# does it (docs.docker.com/engine/install/debian).
#
# The signing key is stored as-is (ASCII-armored .asc, which apt accepts) in
# /etc/apt/keyrings and referenced with Signed-By, so it only vouches for this
# repository. The suite is this release's codename, from /etc/os-release.
#
#   docker-ce, docker-ce-cli  the engine and the CLI
#   containerd.io             containerd and runc, bundled by Docker
#   docker-buildx-plugin      `docker buildx`
#   docker-compose-plugin     `docker compose`
#
# The package enables and starts the docker service itself.
#
# Members of the docker group can use the daemon's socket without sudo. That
# is root access in effect (a container can mount /). The group applies
# after a reboot: the long-lived systemd user manager keeps the old group
# list across a plain logout.

key=/etc/apt/keyrings/docker.asc
tmp="$(mktemp)"
wget -qO "$tmp" https://download.docker.com/linux/debian/gpg
install -d -m 0755 /etc/apt/keyrings
write_file "$key" 0644 < "$tmp"
rm -f "$tmp"
key_changed=$CHANGED

codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
write_file /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: $key
EOF

if [[ $key_changed -eq 1 || $CHANGED -eq 1 ]]; then apt_update; fi
docker_packages=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
apt_install "${docker_packages[@]}"

if in_group "$TARGET_USER" docker; then
  log "unchanged: $TARGET_USER is in docker"
else
  usermod -aG docker "$TARGET_USER"
  log "added $TARGET_USER to docker"
  needs_reboot "docker group membership (a logout can leave the user manager with the old groups)"
fi

verify "apt reads Docker's repository" apt_knows_source download.docker.com
verify_installed "${docker_packages[@]}"
verify "docker-ce installed from Docker's repository" installed_from docker-ce download.docker.com
verify "docker compose works" docker compose version
verify "docker buildx works" docker buildx version
verify "docker service enabled" systemctl is-enabled docker
verify "$TARGET_USER in the docker group" in_group "$TARGET_USER" docker
