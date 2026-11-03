# Terminal system monitors.
#
#   htop    processes, CPU and memory
#   btop    the same plus disks, network and per-core graphs
#   iotop   disk I/O per process; needs root (sudo iotop)

apt_install \
  htop \
  btop \
  iotop

verify_installed htop btop iotop
