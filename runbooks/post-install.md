# Post-install

Steps that need a person, a secret or a physical action. Do them once on every host, after the system and home setup.

## Fingerprints

Enroll through sudo with your username.

```
sudo fprintd-enroll -f right-index-finger "$USER"
sudo fprintd-enroll -f left-index-finger "$USER"
```

## LUKS header backup

The header holds the key slots; if it's damaged, the data is lost even with the passphrase. Keep it encrypted (in a password manager, not as a loose file): the backup plus the passphrase at the time unlocks the disk.

This host's LUKS partition is the device behind its mapping in `/etc/crypttab`:

```
sudo cryptsetup status "$(awk '!/^#/ && NF {print $1; exit}' /etc/crypttab)" | awk '$1 == "device:" {print $2}'
sudo cryptsetup luksHeaderBackup <LUKS partition> --header-backup-file "$(hostname)-luks-header.img"
```

## Firmware updates

The system setup installs fwupd and refreshes its list of updates, but doesn't apply them: installing one reboots into the firmware updater, which mustn't happen in the middle of a setup run, and a firmware flash needs AC power and someone at the laptop.

```
fwupdmgr get-updates
fwupdmgr update # if any are listed; reboots into the updater
```
