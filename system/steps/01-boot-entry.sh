# This host's UEFI boot entry: labelled with the hostname, and kept that way.
#
# Each host boots from its own UEFI entry, labelled with its hostname. The
# Debian installer registers the entry as "debian", and by default every
# grub-efi-amd64 or shim upgrade runs grub-install, which recreates a "debian"
# entry and moves it first in the boot order. With grub2/update_nvram false,
# upgrades only update the files on the ESP and leave the entries as they are.
#
# The entry is created for the ESP mounted at /boot/efi, booting Debian's shim.
# Then the "debian" entries that boot that same shim are deleted. Entries that
# boot anything else (another host's ESP, the firmware's own entries) are
# never touched.
#
# Anything unexpected stops the step before NVRAM is changed: not booted in
# UEFI mode, no ESP at /boot/efi or no shim on it, booted from an entry that
# isn't this host's shim, or an entry with this hostname that boots
# something else (left from an earlier installation with the same hostname).

nvram_off() { debconf-show grub-efi-amd64 | grep -E '^[* ] grub2/update_nvram: false$' >/dev/null; }

if nvram_off; then
  log "unchanged: grub2/update_nvram is false"
else
  echo 'grub-efi-amd64 grub2/update_nvram boolean false' | debconf-set-selections
  log "set grub2/update_nvram to false"
fi

# --- what this host boots from ----------------------------------------------

[[ -d /sys/firmware/efi/efivars ]] || fail "not booted in UEFI mode"
command -v efibootmgr >/dev/null || fail "efibootmgr is not installed"

label="$(hostname)"
[[ "$label" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || fail "hostname '$label' isn't a plain host name"
[[ "$label" != debian ]] || fail "the hostname is 'debian', the label this step replaces"

esp="$(findmnt -no SOURCE --mountpoint /boot/efi)" || fail "nothing is mounted at /boot/efi"
esp="$(readlink -f "$esp")"
[[ "$(findmnt -no FSTYPE --mountpoint /boot/efi)" == vfat ]] || fail "/boot/efi ($esp) isn't a FAT filesystem"
[[ "$(lsblk -dno PARTTYPE "$esp")" == c12a7328-f81f-11d2-ba4b-00a0c93ec93b ]] \
  || fail "$esp, mounted at /boot/efi, isn't an EFI System Partition"

esp_disk="/dev/$(lsblk -dno PKNAME "$esp")"
[[ "$(lsblk -dno TYPE "$esp_disk" 2>/dev/null)" == disk ]] || fail "can't find the disk holding $esp"
esp_part="$(cat "/sys/class/block/${esp##*/}/partition")"
[[ "$esp_part" =~ ^[0-9]+$ ]] || fail "can't find the partition number of $esp"
esp_partuuid="$(lsblk -dno PARTUUID "$esp")"
[[ -n "$esp_partuuid" ]] || fail "$esp has no partition UUID"

loader='\EFI\debian\shimx64.efi'
[[ -f /boot/efi/EFI/debian/shimx64.efi ]] || fail "no shim at /boot/efi/EFI/debian/shimx64.efi"

log "ESP: $esp (disk $esp_disk, partition $esp_part, PARTUUID $esp_partuuid)"

# --- reading the entries ----------------------------------------------------

# Print each boot entry as NUMBER<TAB>LABEL<TAB>OURS, where OURS is 1 when the
# entry boots the shim on this host's ESP (matched by partition number and
# PARTUUID, so the same path on another ESP doesn't count).
boot_entries() {
  local listing
  listing="$(efibootmgr -v)" || return 1
  HD="hd($esp_part,gpt,$esp_partuuid," FILE="file($loader)" awk '
    /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\*? / {
      num = substr($0, 5, 4)
      rest = substr($0, index($0, " ") + 1)
      tab = index(rest, "\t")
      if (tab) { label = substr(rest, 1, tab - 1); path = tolower(substr(rest, tab + 1)) }
      else { label = rest; path = "" }
      ours = index(path, tolower(ENVIRON["HD"])) && index(path, tolower(ENVIRON["FILE"]))
      print num "\t" label "\t" (ours ? 1 : 0)
    }' <<<"$listing"
}

# entry_numbers LABEL OURS: the numbers of the entries with LABEL ("" for any
# label), and with OURS 1 or 0 ("" for either), one per line.
entry_numbers() {
  local entries
  entries="$(boot_entries)" || return 1
  awk -F'\t' -v label="$1" -v ours="$2" \
    '(label == "" || $2 == label) && (ours == "" || $3 == ours) { print $1 }' <<<"$entries"
}

boot_var() { efibootmgr | awk -v name="$1:" '$1 == name { print $2 }'; }

# The entry with the hostname exists once, boots this host, and is in the
# boot order.
hostname_entry_ok() {
  local all ours order
  all="$(entry_numbers "$label" "")" || return 1
  ours="$(entry_numbers "$label" 1)" || return 1
  [[ -n "$ours" && "$all" == "$ours" && "$(wc -l <<<"$ours")" -eq 1 ]] \
    || { echo "expected one entry '$label' booting $loader on $esp" >&2; return 1; }
  order="$(boot_var BootOrder)" || return 1
  [[ ",$order," == *",$ours,"* ]] || { echo "Boot$ours isn't in BootOrder ($order)" >&2; return 1; }
}

no_debian_entry() {
  local found
  found="$(entry_numbers debian 1)" || return 1
  [[ -z "$found" ]]
}

# --- checks before changing NVRAM -------------------------------------------

# This boot came through an entry that boots this host's shim. Confirms
# both that the entries are read correctly and that this is the host whose
# ESP is mounted.
current="$(boot_var BootCurrent)"
ours_all="$(entry_numbers "" 1)"
[[ -n "$current" ]] || fail "efibootmgr shows no BootCurrent"
grep -qx "$current" <<<"$ours_all" \
  || fail "booted from Boot$current, which doesn't boot $loader on $esp; boot this host from its own entry and run again"

named="$(entry_numbers "$label" "")"
named_ours="$(entry_numbers "$label" 1)"

if [[ -n "$named" && "$named" != "$named_ours" ]]; then
  fail "entry '$label' (Boot$(paste -sd, - <<<"$named")) boots something other than $loader on $esp; check it with efibootmgr -v and delete it if it's left from an earlier installation"
elif [[ -n "$named" && "$(wc -l <<<"$named")" -gt 1 ]]; then
  fail "several entries are labelled '$label' (Boot$(paste -sd, - <<<"$named")); delete the extra ones with efibootmgr"
fi

# --- the entry with the hostname --------------------------------------------

if [[ -n "$named" ]]; then
  log "unchanged: Boot$named '$label' boots $esp"
else
  efibootmgr --create --disk "$esp_disk" --part "$esp_part" --label "$label" --loader "$loader" >/dev/null
  hostname_entry_ok || fail "created an entry '$label' but can't find it; check efibootmgr -v"
  log "created boot entry '$label' for $esp"
fi

# --- the installer's "debian" entry -----------------------------------------

# Only once the entry with the hostname is in place, so the shim stays bootable.
hostname_entry_ok || fail "the entry '$label' isn't in place; leaving the 'debian' entries"
debian_ours="$(entry_numbers debian 1)"
for num in $debian_ours; do
  efibootmgr --bootnum "$num" --delete-bootnum >/dev/null
  log "deleted boot entry Boot$num 'debian' (replaced by '$label')"
done

debian_other="$(entry_numbers debian 0)"
if [[ -n "$debian_other" ]]; then
  warn "left entries labelled 'debian' that boot something else: Boot$(paste -sd, - <<<"$debian_other")"
fi

verify "GRUB upgrades leave the UEFI entries alone" nvram_off
verify "boot entry '$label' boots $esp" hostname_entry_ok
verify "no 'debian' entry boots $esp" no_debian_entry
