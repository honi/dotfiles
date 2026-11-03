# GRUB menu entries that boot the other hosts on this machine, from
# /etc/grub.d/35_other-hosts. update-grub runs it, and it adds an entry for
# each UEFI boot entry that boots Debian's shim from another EFI System
# Partition, labelled like that boot entry. Arriving from another host's
# "Switch host" entry boots this host's default entry without the menu.

put_file /etc/grub.d/35_other-hosts 0755
if [[ $CHANGED -eq 1 ]]; then needs_grub "GRUB entries for the other hosts"; fi

# The script runs and prints the switched_host check.
other_hosts_script_ok() {
  local out
  out="$(/etc/grub.d/35_other-hosts 2>/dev/null)" || return 1
  # shellcheck disable=SC2016 # the GRUB variable, literally
  grep -qF 'if [ "${switched_host}" = 1 ]; then' <<<"$out"
}

verify "GRUB menu script for the other hosts is executable" test -x /etc/grub.d/35_other-hosts
verify "GRUB menu script for the other hosts runs" other_hosts_script_ok
