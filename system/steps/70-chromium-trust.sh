# The tools that let Chromium-based browsers trust the system certificate
# store: certutil and modutil manage the NSS database Chromium reads, and
# p11-kit's trust module serves the system store to it.

packages=(
  libnss3-tools
  p11-kit-modules
)

apt_install "${packages[@]}"

verify_installed "${packages[@]}"
verify "modutil present" test -x /usr/bin/modutil
verify "p11-kit trust module present" test -f /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so
