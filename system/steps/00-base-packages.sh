# Base packages that don't require any set up.

apt_update
apt_install \
  wget \
  gpg \
  ca-certificates \
  bind9-dnsutils \
  htop \
  btop \
  iotop \
  tree \
  rsync

verify_installed wget gpg ca-certificates bind9-dnsutils htop btop iotop tree rsync
