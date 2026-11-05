# Read access to the system journal without sudo.
#
# The systemd-journal group owns the journal files, so its members can run
# journalctl and see every service's logs. The group is read-only: it grants
# no write access to the journal and no control over services.
#
# The group applies after a reboot: the long-lived systemd user manager
# keeps the old group list across a plain logout.

if in_group "$TARGET_USER" systemd-journal; then
  log "unchanged: $TARGET_USER is in systemd-journal"
else
  usermod -aG systemd-journal "$TARGET_USER"
  log "added $TARGET_USER to systemd-journal"
  needs_reboot "systemd-journal group membership (a logout can leave the user manager with the old groups)"
fi

verify "$TARGET_USER in systemd-journal" in_group "$TARGET_USER" systemd-journal
