# Fingerprints

The reader is match-on-chip: the fingerprint templates live on the sensor itself, and each host's `/var/lib/fprint` only holds records that point to them. Both hosts use the same sensor, so they share its storage.

When an enrollment finds the sensor full, or the finger already on it, fprintd deletes every print on the sensor that this host has no record of, assuming it's left from an old installation. The other host's prints look exactly like that, so enrolling on each host separately wipes the other host's prints.

So enroll on one host and copy the records to the other. Both hosts then know every print on the sensor, and fprintd deletes nothing. The records sit under the username, so it must be the same on both hosts.

## Set up

1. On one host, enroll through sudo with your username:

   ```
   sudo fprintd-enroll -f right-index-finger "$USER"
   ```

2. Copy the records to a USB stick or another computer. The two hosts never run at the same time.

   ```
   sudo tar -C /var/lib -czf fprint.tar.gz fprint
   ```

3. On the other host, restore them and restart fprintd:

   ```
   sudo tar -C /var/lib -xzf fprint.tar.gz
   sudo systemctl restart fprintd
   ```

   Delete `fprint.tar.gz` afterwards.

4. On both hosts, touch the sensor when asked:

   ```
   fprintd-verify
   ```

   Each should print `verify-match`.
