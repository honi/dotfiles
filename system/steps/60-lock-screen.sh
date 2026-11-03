# Lock screen PAM: password only.
#
# Regolith locks with gtklock (Super+Escape, idle, before suspend). Debian's
# PAM file for it includes the login stack, which asks for the fingerprint
# after the password. A lock screen only checks credentials, so its file is
# a single password check through pam_unix.

pam=/etc/pam.d/gtklock
backup_once "$pam"
put_file "$pam"

verify "gtklock PAM is password only" pam_password_only "$pam"
