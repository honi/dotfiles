# GRUB menu entries that boot the other hosts on this machine, from
# /etc/grub.d/35_other-hosts. update-grub runs it, and it adds an entry for
# each UEFI boot entry that boots Debian's shim from another EFI System
# Partition, labelled like that boot entry.

put_file /etc/grub.d/35_other-hosts 0755
if [[ $CHANGED -eq 1 ]]; then needs_grub "GRUB entries for the other hosts"; fi

# The script runs and prints only menu entries (or nothing).
other_hosts_script_ok() {
  local out
  out="$(/etc/grub.d/35_other-hosts)" || return 1
  [[ -z "$out" ]] || grep -q "^menuentry " <<<"$out"
}

verify "GRUB menu script for the other hosts is executable" test -x /etc/grub.d/35_other-hosts
verify "GRUB menu script for the other hosts runs" other_hosts_script_ok
