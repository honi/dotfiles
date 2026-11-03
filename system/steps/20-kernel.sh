# Kernel from trixie-backports.
#
# linux-image-amd64 is a metapackage that always depends on the newest kernel
# of its source. Installed from backports, it puts the machine on the
# backports kernel series, and later upgrades keep following it.
#
# A newer kernel is installed only after confirming at the prompt. Declining
# keeps the current kernel for this run, including through the package
# upgrade at the end; the next run asks again.
#
# apt keeps the previous kernel installed as a fallback; GRUB lists it under
# "Advanced options".

installed="$(dpkg-query -W -f='${Version}' linux-image-amd64 2>/dev/null || true)"
candidate="$(backports_candidate linux-image-amd64)"
[[ -n "$candidate" ]] || fail "no linux-image-amd64 in trixie-backports"

if [[ "$installed" == "$candidate" ]]; then
  log "unchanged: kernel $installed"
else
  [[ -t 0 ]] || fail "kernel $candidate is available (installed: ${installed:-none}); run from a terminal to confirm"
  read -r -p "    install kernel $candidate (installed: ${installed:-none})? [y/N] " answer
  if [[ "$answer" == [yY]* ]]; then
    apt_install_backports linux-image-amd64
    needs_reboot "new kernel $candidate"
  else
    decline_kernel
    log "kept kernel $installed"
  fi
fi

verify_installed linux-image-amd64
if ! kernel_declined; then
  verify "linux-image-amd64 is the newest trixie-backports version" backports_current linux-image-amd64
fi
