# Boot order

Each host has its own UEFI boot entry, labelled with its hostname. The firmware boots the first entry in `BootOrder`. When a host's system setup creates its entry, the entry goes first, so the host set up most recently is the default.

## Pick one at power-on

The GRUB menu waits three seconds and lists the other host as **Switch host: <hostname>**, below this host's own entries. Pick it with the arrow keys and Enter. It boots the other host's default entry directly, without showing its menu.

The firmware's boot menu works too: press **F12** and choose the entry with the hostname.

The GRUB menu finds the other host when `update-grub` runs. After the other host is reinstalled, its ESP is formatted again, and the entry points nowhere until `sudo update-grub` runs on this host. The other host also needs its own boot entry: it's listed only once its system setup has run.

## See the entries

From either host:

```
sudo efibootmgr
```

- `BootOrder`: the order the firmware tries the entries in.
- `BootCurrent`: the entry this boot came from.
- `Boot####`: one line per entry, with its number and label.

## Change the default

List every entry from `BootOrder` in the new order, with the host you want first. Entries left out of the list aren't tried.

```
sudo efibootmgr --bootorder <first>,<second>,...
sudo efibootmgr # check BootOrder
```

The firmware setup (**F2** at power-on) can change the order too.

## Boot the other host once

Sets the entry for the next boot only and keeps the order:

```
sudo efibootmgr --bootnext <number>
sudo reboot
```

## When the order changes

GRUB and shim upgrades don't touch the entries, and running the system setup again keeps an existing entry where it is. The order changes only when the setup creates an entry, after a reinstall or a hostname change. Set it again after that.
