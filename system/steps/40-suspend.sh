# Suspend: don't freeze user sessions first.
#
# systemd-sleep freezes user.slice (every login session's processes) before
# the kernel suspends. A process reading from a FUSE file system served from
# the same session (e.g. media playing from a network share through gvfs)
# can't be frozen once the FUSE server is: suspend hangs with the desktop
# frozen, then fails. With the setting off, only the kernel freezes
# processes, all at once. systemd-sleep reads the variable, so the unit needs
# a daemon-reload.

write_file /etc/systemd/system/systemd-suspend.service.d/no-freeze-user-sessions.conf <<'EOF'
[Service]
Environment=SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false
EOF
if [[ $CHANGED -eq 1 ]]; then
  systemctl daemon-reload
fi
