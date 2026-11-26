# Fingerprint reader for sudo and polkit.
#
# fprintd drives the Goodix reader (27c6:609c) through libfprint and stores
# enrolled fingers under /var/lib/fprint. libpam-fprintd is its PAM module.
#
# pam-auth-update rebuilds Debian's common PAM files (common-auth and
# friends) from the profiles in /usr/share/pam-configs. Enabling the fprintd
# profile adds pam_fprintd to common-auth, which sudo, console login and
# polkit all include: they accept a finger touch, and fall back to the
# password if the sensor isn't touched before the timeout.
#
# With the lid closed the sensor can't be reached, so a second profile ahead
# of fprintd's skips the fingerprint prompt and goes straight to the password.
# Its jump skips exactly one line, the fprintd entry, so the two profiles are
# only ever enabled together.

apt_install \
  fprintd \
  libpam-fprintd
put_file /usr/local/bin/lid-closed 0755
put_file /usr/share/pam-configs/fprintd-lid-open
pam-auth-update --enable fprintd fprintd-lid-open
log "fingerprint enabled in common-auth"

verify_installed fprintd libpam-fprintd
verify "pam_fprintd in common-auth" grep -q pam_fprintd /etc/pam.d/common-auth
verify "lid check precedes pam_fprintd in common-auth" \
  bash -c "grep -A1 lid-closed /etc/pam.d/common-auth | grep -q pam_fprintd"
