# QEMU/KVM for running local virtual machines from the command line.
#
#   qemu-system-x86             the x86-64 emulator with KVM acceleration
#   qemu-system-gui             GTK display and audio backends (PipeWire)
#   qemu-system-modules-opengl  virgl, for GL-accelerated virtio-gpu
#   qemu-utils                  qemu-img, for disk images and overlays
#   ovmf                        UEFI firmware
#   cloud-image-utils           cloud-localds, for cloud-init seed images
#   virtiofsd                   shares host directories with a guest
#
# /dev/kvm is opened through the seat's uaccess ACL, so no kvm group is
# needed.

vm_packages=(qemu-system-x86 qemu-system-gui qemu-system-modules-opengl qemu-utils ovmf cloud-image-utils virtiofsd)
apt_install "${vm_packages[@]}"

verify_installed "${vm_packages[@]}"
verify "qemu has KVM acceleration" bash -c 'qemu-system-x86_64 -accel help | grep -qx kvm'
verify "qemu has the GTK display" bash -c 'qemu-system-x86_64 -display help | grep -qx gtk'
