# Fingerprints

The reader is match-on-chip: the fingerprint templates live on the sensor itself, and each host's `/var/lib/fprint` only holds records that point to them. Both hosts use the same sensor, so they share its storage.

When an enrollment finds the sensor full, or the finger already on it, fprintd deletes every print on the sensor that this host has no record of, assuming it's left from an old installation. The other host's prints look exactly like that, so enrolling on each host separately wipes the other host's prints.

So enroll on one host and copy the records to the other. Both hosts then know every print on the sensor, and fprintd deletes nothing. The records sit under the username, so it must be the same on both hosts.

## Set up

1. On each host, delete your prints. This also removes them from the sensor, clearing out stale ones:

   ```
   sudo fprintd-delete "$USER"
   ```

2. On one host, enroll through sudo with your username:

   ```
   sudo fprintd-enroll -f right-index-finger "$USER"
   sudo fprintd-enroll -f left-index-finger "$USER"
   ```

3. Copy the records to a USB stick or another computer. The two hosts never run at the same time.

   ```
   sudo tar -C /var/lib -czf fprint.tar.gz fprint
   ```

4. On the other host, restore them and restart fprintd:

   ```
   sudo tar -C /var/lib -xzf fprint.tar.gz
   sudo systemctl restart fprintd
   ```

   Delete `fprint.tar.gz` from the stick afterwards.

5. On both hosts, touch the sensor when asked:

   ```
   fprintd-verify
   ```

   Each should print `verify-match`.

## Change the enrolled fingers

Enroll or delete on one host, then copy the records to the other as in steps 3 and 4. Deleting a finger on one host removes it from the sensor for both. Until you copy again, the other host still lists it, but it can't match.

## After a reinstall

- **One host:** copy the records from the other host to the new one (steps 3 to 5). Don't enroll on the new host.
- **Both hosts:** follow [Set up](#set-up).

## Enrolling fails

`enroll-duplicate` or `enroll-data-full` means the sensor holds prints that neither host has a record of, and fprintd couldn't delete them. Clear the sensor's storage, then follow [Set up](#set-up). `fprintd-delete` only removes prints the host knows about. Prints neither host knows need a tool that clears the whole storage, such as the community script in [this Framework forum thread](https://community.frame.work/t/solved-clear-fingerprint-reader-storage-fingerprint-reader-problems/22951). Read it before running it.
