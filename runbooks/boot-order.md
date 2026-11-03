# Boot order

Each host has its own UEFI boot entry, labelled with its hostname. The firmware boots the first entry in `BootOrder`. When a host's system setup creates its entry, the entry goes first, so the host set up most recently is the default.

## Pick one at power-on

Press **F12** and choose the entry with the hostname.

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
