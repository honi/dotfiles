# Desktop command-line tools.
#
#   grimshot       screenshot helper for Sway: grim captures, slurp selects
#                  an area
#   wl-clipboard   wl-copy/wl-paste, the Wayland clipboard
#   libnotify-bin  notify-send, desktop notifications from scripts

apt_install \
  grimshot \
  wl-clipboard \
  libnotify-bin

verify_installed grimshot wl-clipboard libnotify-bin
