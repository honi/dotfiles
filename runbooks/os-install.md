# OS install

Installs Debian 13 (trixie) by hand.

The laptop holds two fully isolated Debian installs, side by side on the same disk. Each has its own ESP, `/boot` and LUKS container with its own passphrase, so neither can read the other's data or overwrite its bootloader. Each install uses one overlay, and the overlay's `runbooks/os-install.md` has the values this runbook asks for: install order, hostname, partitions and their sizes, volume group. Install the first one completely before starting the second.

## Preamble

### Hardware

| Component | Part |
| --- | --- |
| Mainboard | Framework Laptop 13 Pro DIY, Intel Core Ultra X7 358H (Panther Lake) |
| Memory | 64 GB LPCAMM2 LPDDR5X-8533 |
| Storage | 2 TB SanDisk SN7100 NVMe |
| Wi-Fi | Intel Wi-Fi 7 BE211 |
| Keyboard | US English |
| Expansion cards | Ethernet (Realtek RTL8156), USB-A, HDMI, 2× USB-C |

The Ethernet card works with the stock kernel and is the network for the whole install. USB tethering from a phone also works.

### Installer USB

1. From [cdimage.debian.org/debian-cd/current/amd64/iso-cd](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/), download `debian-13.x.y-amd64-netinst.iso`, `SHA512SUMS` and `SHA512SUMS.sign`.
2. Verify them. Check the key fingerprint against [debian.org/CD/verify](https://www.debian.org/CD/verify):

   ```
   gpg --keyserver keyring.debian.org --recv-keys DF9B9C49EAA9298432589D76DA87E80D6294BE9B
   gpg --verify SHA512SUMS.sign SHA512SUMS
   sha512sum --ignore-missing -c SHA512SUMS   # macOS: shasum -a 512 --ignore-missing -c SHA512SUMS
   ```

3. Write it to the stick (this erases the stick, so double-check the device):
   - Linux: `lsblk`, `sudo dd if=debian-13*-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync`
   - macOS: `diskutil list`, `diskutil unmountDisk /dev/diskN`, `sudo dd if=debian-13*-netinst.iso of=/dev/rdiskN bs=4m status=progress`

### Firmware

1. Power on, press **F2**. Check that **Secure Boot** is enabled; Debian boots through Microsoft-signed shim. Save and exit.
2. Plug in Ethernet and the USB stick, power on, press **F12** and pick the USB entry.

F12 is also how you switch between installs later: each has its own UEFI boot entry, labelled with its hostname.

## Debian installer

Only the screens where the answer isn't the default.

| Screen | Choice |
| --- | --- |
| Boot menu | Graphical install |
| Location | other → South America → Argentina |
| Locale | en\_US.UTF-8 |
| Keyboard | American English |
| Missing firmware (iwlwifi) | **No**: the installer kernel can't drive this card anyway |
| Primary network interface | the wired `enx…` interface |
| Hostname | from the overlay's runbook; domain empty |
| Root password | **empty**: disables root login and gives your user `sudo` |
| Partitioning | see below |
| Software selection | untick **Debian desktop environment** and **GNOME**; keep **standard system utilities**; tick **SSH server** |

### Disk layout

Each install is three partitions: ESP, `/boot`, and a LUKS container holding an LVM volume group. The first install creates the partition table and takes the start of the disk; the second takes what's left. Every volume group gets the same logical volumes; what's left stays free in the VG for growing them later.

| LV | Size | Use as | Mount point | Reserved blocks |
| --- | --- | --- | --- | --- |
| `root` | 80 GB | Ext4 | `/` | default (5%) |
| `var` | 120 GB | Ext4 | `/var` | default (5%) |
| `home` | 300 GB | Ext4 | `/home` | 1% |
| `nix` | 80 GB | Ext4 | Enter manually → `/nix` | 1% |
| `swap` | 16 GB | swap area | | |

Encryption: keep the defaults, except **Erase data: No**.

### Partitioning: first install

1. **Partition disks → Manual.**
2. Select the disk (`nvme0n1`, the line with the size) → **Create new empty partition table** → Yes.
3. FREE SPACE → Create a new partition → `1 GB` → Beginning → Use as: **EFI System Partition** → Done.
4. FREE SPACE → Create → `2 GB` → Beginning → Use as: **Ext4** → Mount point: `/boot` → Done.
5. FREE SPACE → Create → the LUKS size → Beginning → Use as: **physical volume for encryption** → Erase data: **No** → Done.
6. **Configure encrypted volumes** → Yes → Create encrypted volumes → tick only the new LUKS partition → Finish → enter this install's passphrase twice.
7. **Configure the Logical Volume Manager** → Yes → Create volume group → the VG name → select `/dev/mapper/<LUKS partition>_crypt`.
8. Create logical volume → the VG → each LV from the table, name and size → Finish.
9. Select the partition under each LV and set it up from the table (Use as, mount point, reserved blocks).
10. **Finish partitioning and write changes to disk** → Yes. The rest of the disk stays as FREE SPACE.

### Partitioning: second install

1. **Partition disks → Manual.** Don't create a new partition table.
2. Select the first install's ESP (shown as "EFI System Partition") → Use as: **do not use** → Done. Leave its `/boot` and LUKS partitions as they are.
3. FREE SPACE → Create a new partition → `1 GB` → Beginning → Use as: **EFI System Partition** → Done.
4. FREE SPACE → Create → `2 GB` → Beginning → Use as: **Ext4** → Mount point: `/boot` → Done.
5. FREE SPACE → Create → all remaining space → Use as: **physical volume for encryption** → Erase data: **No** → Done.
6. **Configure encrypted volumes** → Yes → Create encrypted volumes → tick only the new LUKS partition → Finish → enter this install's passphrase twice.
7. **Configure the Logical Volume Manager** → Yes → Create volume group → the VG name → select `/dev/mapper/<LUKS partition>_crypt`.
8. Create logical volume → the VG → each LV from the table → Finish.
9. Select the partition under each LV and set it up from the table.
10. **Finish partitioning and write changes to disk** → Yes.

## First boot

The initramfs asks for the LUKS passphrase, then you land on a text login. Ethernet works; Wi-Fi doesn't yet.

To work from another computer: `ip -4 addr` shows the `enx…` address, then `ssh <user>@<ip>`.

1. Give the install's UEFI entry its hostname. The installer named it `debian` and the next install would reuse that entry. So do this after each install, before starting the next one.

   ```
   sudo efibootmgr # note the number of the "debian" entry
   sudo efibootmgr --create --disk /dev/nvme0n1 --part <ESP partition number> \
     --label "$(hostname)" --loader '\EFI\debian\shimx64.efi'
   sudo efibootmgr --bootnum <number> --delete-bootnum
   ```

2. Get this repository and apply the base:

   ```
   sudo apt install git
   git clone https://github.com/honi/dotfiles.git ~/dotfiles
   ~/dotfiles/system/setup.sh          # offers to reboot at the end; say yes
   ~/dotfiles/home/setup.sh            # after the reboot, from a text console or SSH
   ```

   If the system setup stops at a failing step, fix the cause and run it again: it resumes at that step. After the reboot the laptop shows the login screen; don't log in there yet, do it over SSH or on a
   text console (Ctrl+Alt+F3).

3. Install the overlay and apply it:

   ```
   ~/dotfiles/utils/install-overlay.sh
   ~/dotfiles/system/setup.sh
   ~/dotfiles/home/setup.sh
   ~/dotfiles/secrets/setup.sh
   ```

4. Follow [post-install.md](post-install.md), then the overlay's own `runbooks/`.
