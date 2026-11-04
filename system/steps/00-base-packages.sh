# Base packages: the tools later steps rely on, and terminal system monitors.
#
#   wget, gpg, ca-certificates   downloading and checking apt keys and files
#   bind9-dnsutils   dig, nslookup and nsupdate for DNS lookups
#   htop    processes, CPU and memory
#   btop    the same plus disks, network and per-core graphs
#   iotop   disk I/O per process; needs root (sudo iotop)

apt_update
apt_install \
  wget \
  gpg \
  ca-certificates \
  bind9-dnsutils \
  htop \
  btop \
  iotop

verify_installed wget gpg ca-certificates bind9-dnsutils htop btop iotop
