# Storage: TRIM and dm-crypt latency on NVMe.
#
# TRIM tells the SSD which blocks are free so it can erase them ahead of time.
# Two settings make it work through LUKS and LVM:
#   - `discard` in /etc/crypttab lets TRIM requests pass through dm-crypt
#     (the Debian installer sets it; checked here, not changed);
#   - fstrim.timer trims every mounted filesystem once a week.
#
# dm-crypt work queues: by default dm-crypt hands encryption to kernel worker
# threads. On NVMe that only adds latency; the two --perf-no_*_workqueue flags
# make it encrypt in the I/O path instead. `cryptsetup refresh --persistent`
# applies them to the open mapping and stores them in the LUKS2 header, so
# every later unlock uses them too.
#
# Network shares: gvfs-fuse exposes shares mounted in the Files app (SMB, SFTP,
# ...) as real paths under /run/user/$UID/gvfs, so apps without gvfs support
# can open them as local files.

if grep -qE '^[^#].*\bdiscard\b' /etc/crypttab; then
  log "crypttab passes TRIM through (discard)"
else
  warn "/etc/crypttab has no discard option; TRIM won't reach the SSD"
fi

systemctl enable --now fstrim.timer >/dev/null
log "fstrim.timer enabled"

# The LUKS mapping that holds this OS's volume group (first crypttab entry).
mapping="$(awk '!/^#/ && NF {print $1; exit}' /etc/crypttab)"

# The open mapping uses the flags...
mapping_bypasses_workqueues() {
  local table
  table="$(dmsetup table "$mapping")" && [[ "$table" == *"no_read_workqueue no_write_workqueue"* ]]
}
# ...and the LUKS2 header stores them for the next unlock.
header_bypasses_workqueues() {
  local device dump
  device="$(cryptsetup status "$mapping" | awk '$1 == "device:" { print $2 }')"
  dump="$(cryptsetup luksDump "$device")" || return 1
  grep -E '^Flags:.*no-read-workqueue' <<<"$dump" | grep -q 'no-write-workqueue'
}

if [[ -z "$mapping" ]]; then
  warn "no LUKS mapping found in /etc/crypttab; skipping workqueue flags"
elif mapping_bypasses_workqueues; then
  log "unchanged: $mapping already bypasses the workqueues"
else
  cryptsetup refresh --persistent --perf-no_read_workqueue --perf-no_write_workqueue "$mapping"
  log "set no_read_workqueue/no_write_workqueue on $mapping"
fi

apt_install gvfs-fuse

verify "fstrim.timer enabled" systemctl is-enabled fstrim.timer
if [[ -n "$mapping" ]]; then
  verify "$mapping bypasses the dm-crypt workqueues" mapping_bypasses_workqueues
  verify "LUKS header keeps the workqueue flags" header_bypasses_workqueues
fi
verify_installed gvfs-fuse
