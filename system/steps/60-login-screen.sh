# Login screen: greetd with tuigreet, password-only, keyring unlocked.
#
# greetd is a minimal login daemon; it runs a greeter (here tuigreet, a text
# UI) on VT 7 as the _greetd user, then starts the chosen session for the
# user who logged in.
#
#   /etc/greetd/config.toml  tuigreet as the greeter
#   /etc/pam.d/greetd        the login stack with a password-only check, so
#                            pam_gnome_keyring gets the typed password and
#                            unlocks the GNOME Keyring with it (a fingerprint
#                            login leaves the keyring locked)
#
# libpam-gnome-keyring provides pam_gnome_keyring.so. graphical.target makes
# boot continue to the display manager.

apt_install \
  greetd \
  tuigreet \
  libpam-gnome-keyring

put_file /etc/greetd/config.toml

pam=/etc/pam.d/greetd
backup_once "$pam"
put_file "$pam"

systemctl enable greetd >/dev/null
if [[ "$(systemctl get-default)" != graphical.target ]]; then
  systemctl set-default graphical.target
  needs_reboot "greetd login screen"
fi
log "greetd enabled at boot"

verify_installed greetd tuigreet libpam-gnome-keyring
verify "tuigreet on PATH" command -v tuigreet
verify "greetd PAM is password only" pam_password_only "$pam"
verify "greetd enabled" systemctl is-enabled greetd
verify "boots to graphical.target" test "$(systemctl get-default)" = graphical.target
