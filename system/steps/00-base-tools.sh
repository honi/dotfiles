# Base tools the later steps rely on.

apt_update
apt_install \
  wget \
  gpg \
  ca-certificates

verify_installed wget gpg ca-certificates
