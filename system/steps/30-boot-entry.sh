# Keep GRUB upgrades away from the UEFI boot entries.
#
# Each install boots from its own UEFI entry, labelled with its hostname.
# By default every grub-efi-amd64 or shim upgrade runs grub-install, which
# recreates a "debian" entry and moves it first in the boot order. With
# grub2/update_nvram false, upgrades only update the files on the ESP and
# leave the entries as they are.

nvram_off() { debconf-show grub-efi-amd64 | grep -E '^[* ] grub2/update_nvram: false$' >/dev/null; }

if nvram_off; then
  log "unchanged: grub2/update_nvram is false"
else
  echo 'grub-efi-amd64 grub2/update_nvram boolean false' | debconf-set-selections
  log "set grub2/update_nvram to false"
fi

verify "GRUB upgrades leave the UEFI entries alone" nvram_off
