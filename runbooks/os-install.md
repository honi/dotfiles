# OS install

The laptop holds two Debian 13 (trixie) hosts on the same disk, fully isolated from each other. Each host uses one overlay. Install the first one completely before starting the second.

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

F12 is also how you switch between hosts later: each has its own UEFI boot entry, labelled with its hostname. To switch hosts from the GRUB menu or change which one boots by default, see [multi-boot.md](multi-boot.md).

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
| Hostname | different per host; domain empty |
| Root password | **empty**: disables root login and gives your user `sudo` |
| Partitioning | see below; for a reinstall, see [Reinstallation](#reinstallation) |
| Software selection | untick **Debian desktop environment** and **GNOME**; keep **standard system utilities**; tick **SSH server** |

### Disk layout

Each host is three partitions: ESP, `/boot`, and a LUKS container holding an LVM volume group. The first host creates the partition table and takes the start of the disk; the second takes what's left.

| | First host | Second host |
| --- | --- | --- |
| ESP | p1, 1 GB | p4, 1 GB |
| `/boot` | p2, 2 GB | p5, 2 GB |
| LUKS | p3, 1200 GB | p6, the rest (~800 GB) |
| LUKS mapping | `nvme0n1p3_crypt` | `nvme0n1p6_crypt` |
| Volume group | `<vg1>` (~600 GB stays free) | `<vg2>` (~200 GB stays free) |

Pick a name for each volume group in place of `<vg1>` and `<vg2>`. Every volume group gets the same logical volumes; what's left stays free in the VG for growing them later.

| LV | Size | Use as | Mount point | Reserved blocks |
| --- | --- | --- | --- | --- |
| `root` | 80 GB | Ext4 | `/` | default (5%) |
| `var` | 120 GB | Ext4 | `/var` | default (5%) |
| `home` | 300 GB | Ext4 | `/home` | 1% |
| `nix` | 80 GB | Ext4 | Enter manually → `/nix` | 1% |
| `swap` | 16 GB | swap area | | |

Encryption: keep the defaults, except **Erase data: No**.

### Partitioning: first host

1. **Partition disks → Manual.**
2. Select the disk (`nvme0n1`, the line with the size) → **Create new empty partition table** → Yes.
3. FREE SPACE → Create a new partition → `1 GB` → Beginning → Use as: **EFI System Partition** → Done.
4. FREE SPACE → Create → `2 GB` → Beginning → Use as: **Ext4** → Mount point: `/boot` → Done.
5. FREE SPACE → Create → `1200 GB` → Beginning → Use as: **physical volume for encryption** → Erase data: **No** → Done.
6. **Configure encrypted volumes** → Yes → Create encrypted volumes → tick only `/dev/nvme0n1p3` → Finish → enter this host's passphrase twice.
7. **Configure the Logical Volume Manager** → Yes → Create volume group → `<vg1>` → select `/dev/mapper/nvme0n1p3_crypt`.
8. Create logical volume → `<vg1>` → each LV from the table, name and size → Finish.
9. Select the partition under each LV and set it up from the table (Use as, mount point, reserved blocks).
10. **Finish partitioning and write changes to disk** → Yes. The rest of the disk stays as FREE SPACE.

### Partitioning: second host

1. **Partition disks → Manual.** Don't create a new partition table. The FREE SPACE below is the large one at the end of the disk, not the ~1 MB gap at the start.
2. Select the first host's ESP (#1, shown as `K  ESP`: the installer picks it up automatically) → Use as: **do not use** → Done. Leave its `/boot` and LUKS partitions as they are.
3. FREE SPACE → Create a new partition → `1 GB` → Beginning → Use as: **EFI System Partition** → Done.
4. FREE SPACE → Create → `2 GB` → Beginning → Use as: **Ext4** → Mount point: `/boot` → Done.
5. FREE SPACE → Create → all remaining space → Use as: **physical volume for encryption** → Erase data: **No** → Done.
6. **Configure encrypted volumes** → Yes → Create encrypted volumes → tick only `/dev/nvme0n1p6` → Finish → enter this host's passphrase twice.
7. **Configure the Logical Volume Manager** → Yes → Create volume group → `<vg2>` → select `/dev/mapper/nvme0n1p6_crypt`.
8. Create logical volume → `<vg2>` → each LV from the table → Finish.
9. Select the partition under each LV and set it up from the table.
10. **Finish partitioning and write changes to disk** → Yes.

## First boot

The initramfs asks for the LUKS passphrase, then you land on a text login. Ethernet works; Wi-Fi doesn't yet.

To work from another computer: `ip -4 addr` shows the `enx…` address, then `ssh <user>@<ip>`.

1. Get this repository and apply the base:

   ```
   sudo apt install git
   git clone https://github.com/honi/dotfiles.git ~/dotfiles
   git -C ~/dotfiles remote set-url --push origin git@github.com:honi/dotfiles.git
   ~/dotfiles/system/setup.sh          # offers to reboot at the end; say yes
   ~/dotfiles/home/setup.sh            # after the reboot, from a text console or SSH
   exec bash -l                        # a new login shell, with the Nix programs on PATH
   ```

   The clone fetches over HTTPS, which needs no key, and pushes over SSH. Do this on each host before installing the next one. If the system setup stops at a failing step, fix the cause and run it again: it resumes at that step. After the reboot the laptop shows the login screen; don't log in there yet, do it over SSH or on a text console (Ctrl+Alt+F3).

2. Install the overlay and apply it:

   ```
   ~/dotfiles/utils/install-overlay.sh
   ~/dotfiles/system/setup.sh
   ~/dotfiles/home/setup.sh
   ~/dotfiles/secrets/setup.sh
   ```

3. Follow [post-install.md](post-install.md), then the overlay's own `runbooks/`.

## Reinstallation

### Reinstall one

Replaces one host and keeps the other.

1. Back up anything on it that isn't in this repository or its overlay.
2. Delete this host's LUKS header backup. With the old passphrase it still decrypts the old data, which stays on the disk.
3. Follow [Firmware](#firmware) and [Debian installer](#debian-installer), with the partitioning below, then [First boot](#first-boot).

Partitioning:

1. **Partition disks → Manual.** Don't create a new partition table.
2. Select the other host's ESP (#4 when reinstalling the first, #1 when reinstalling the second; shown as `K  ESP`, like this host's ESP) → Use as: **do not use** → Done. Leave its `/boot` and LUKS partitions as they are.
3. This host's ESP (p1 or p4) → Use as: **EFI System Partition** → Done.
4. This host's `/boot` (p2 or p5) → Use as: **Ext4** → Format: **yes** → Mount point: `/boot` → Done.
5. This host's LUKS partition (p3 or p6) → Use as: **physical volume for encryption** → Erase data: **No** → Done.
6. **Configure encrypted volumes** → Yes → Create encrypted volumes → tick only this host's (`/dev/nvme0n1p3` or `/dev/nvme0n1p6`) → Finish → enter a new passphrase twice.
7. **Configure the Logical Volume Manager** → Yes → Create volume group → its VG (`<vg1>` or `<vg2>`) → select its `/dev/mapper/…_crypt`.
8. Create logical volume → the VG → each LV from the table → Finish.
9. Select the partition under each LV and set it up from the table.
10. **Finish partitioning and write changes to disk** → Yes.

### Reinstall both

Back up both hosts and delete both LUKS header backups. Then install from scratch: the first host creates a new partition table, which removes everything on the disk.

### Boot entries

The system setup gives each host a UEFI boot entry labelled with its hostname, and deletes the `debian` entry the installer creates. After a reinstall:

- **One host, same hostname:** nothing to do. Its ESP is the same partition as before, so the setup keeps its entry and only deletes the installer's `debian` entry.
- **One host, new hostname:** the setup creates an entry for the new hostname, and the entry with the old one still boots the same ESP. Delete the old one.
- **Both hosts:** the entries from before carry the hostnames but point at the old partitions. When the new host has the same hostname as before, the system setup stops at its old entry. Delete the old entries and run the setup again.

To delete an entry, find its number with `sudo efibootmgr -v` and run `sudo efibootmgr --bootnum <number> --delete-bootnum`.
