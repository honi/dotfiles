# Mesa (OpenGL, Vulkan, EGL, GBM) from trixie-backports.
#
# Mesa is the userspace half of the graphics stack: every desktop and browser
# draws through it. Panther Lake (Xe3) needs Mesa 25.1.6 or newer; trixie has
# 25.0, which refuses this GPU and falls back to CPU rendering.
#
# The pin below raises every package built from the mesa source package
# (src:mesa) to priority 500 when it comes from trixie-backports, the same
# priority as the main archive. With equal priorities apt picks the newer
# version, so all Mesa packages follow backports together, including ones
# pulled in later by other packages. Mesa's packages must all share one
# version, which is why the pin covers the whole source package.
#
# Packages:
#   mesa-libgallium, libgl1-mesa-dri  the drivers themselves
#   libegl-mesa0, libglx-mesa0        EGL (Wayland) and GLX (X11) front-ends
#   libgbm1                           buffer allocation used by compositors
#   mesa-vulkan-drivers               Vulkan driver (ANV)
#   mesa-utils                        eglinfo/glxinfo for checking

write_file /etc/apt/preferences.d/mesa-backports <<'EOF'
Package: src:mesa
Pin: release n=trixie-backports
Pin-Priority: 500
EOF
if [[ $CHANGED -eq 1 ]]; then apt_update; fi

mesa=(
  mesa-libgallium
  libgl1-mesa-dri
  libegl-mesa0
  libglx-mesa0
  libgbm1
  mesa-vulkan-drivers
)

# install (not apt_install): also upgrades Mesa packages that are already
# installed from trixie, so all of them end up on the same version.
apt-get install -y -q "${mesa[@]}" mesa-utils

# Every installed package built from src:mesa (including ones pulled in as
# dependencies) has the same version, and it's new enough for Xe3.
mesa_versions_ok() {
  local versions
  versions="$(dpkg-query -W -f='${db:Status-Abbrev} ${source:Package} ${Version}\n' \
    | awk '$1 == "ii" && $2 == "mesa" { print $3 }' | sort -u)"
  if [[ -n "$versions" && "$versions" != *$'\n'* ]] && dpkg --compare-versions "$versions" ge 25.1.6; then
    return 0
  fi
  echo "installed Mesa versions: ${versions//$'\n'/, }" >&2
  return 1
}

verify_installed "${mesa[@]}" mesa-utils
verify "all Mesa packages on one version, 25.1.6 or newer" mesa_versions_ok
