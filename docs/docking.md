# Docked desk setup

Dell U3225QE (Thunderbolt 4 hub), wired keyboard, Logitech M720 on its Unifying receiver.

## Mouse

M720 channels: 1 is the Unifying receiver (one receiver serves every OS); 2 and 3 are free for Bluetooth to other machines. If the receiver doesn't know the mouse, pair it in Solaar (run `solaar` by hand, then Pair new device); it doesn't start with the session.

## Ports

Connect the laptop to the Dell's Thunderbolt upstream port. The keyboard, the Unifying receiver and the webcam go on the Dell's USB-A ports. Plug the Unifying receiver into the USB-A port next to the ethernet port to avoid interference. The firmware opens the Thunderbolt tunnel before the OS starts, so the Dell's keyboard works at the boot menu and the disk passphrase prompt, with the lid open or closed. Both screens show the same mirrored image there, at one fixed resolution.

Wake from suspend: a key on the Dell-attached keyboard wakes the laptop; the mouse doesn't.

## Cable

A short passive Thunderbolt 4 cable (under 0.8 m) works well. Other cables can be hit or miss: a 0.8 m one failed link training here (tunnel setup errors and a reconnect loop every few seconds in the kernel log).

## BIOS

Set a battery charge limit (for example 80%): docked on AC, the laptop never suspends on idle.
