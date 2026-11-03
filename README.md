# dotfiles

Debian 13 with Regolith (Sway, Dracula) on a Framework Laptop 13 Pro (Intel Panther Lake).

- **base**: this repo. The whole base install, and a working system on its own.
- **overlay**: a private repository that installs on top of base.
- **system layer** (`system/`): packages, hardware, boot and system-wide config, run as root.
- **home layer** (`home/`): user config and user services, with Home Manager.
- **secrets** (`secrets/`): decrypt the overlay's secrets into `$HOME`.

## How to install

Follow [runbooks/os-install.md](runbooks/os-install.md).

## Layout

```
runbooks/
  os-install.md             install Debian (once per host)
  post-install.md           manual steps after install
  overlays.md               how to create an overlay and manage its secrets
  suspend-check.md          measure battery drain during suspend
  multi-boot.md             switch hosts and change which one boots
  fingerprints.md           enroll fingerprints, shared between the hosts
system/
  setup.sh                  runs the base steps, then the overlay's
  lib.sh                    helpers for the steps
  steps/                    NN-name.sh steps; the number orders groups of independent steps
  files/                    files the steps install whole, at the same path
home/
  setup.sh                  applies the overlay's home configuration (or base only without one)
  flake.nix, flake.lock     pins nixpkgs and Home Manager; mkHome for overlays
  modules/                  default.nix, modules, and files/ they use
secrets/
  setup.sh                  decrypts the overlay's secrets into $HOME
  add.sh                    encrypts files from $HOME into the overlay
utils/
  create-overlay-keys.sh    generates a new overlay's deploy and age keys
  install-overlay.sh        clones an overlay with its deploy key from Bitwarden
  pin-base.sh               pins the overlay to this repo's latest commit on GitHub, applies, pushes the overlay
  bitwarden.sh              Bitwarden CLI helpers for the scripts
```

## Day to day

The setups are idempotent: change the repo or the overlay, then run the setup to converge. Anything they don't manage stays as it is.

| Task | Command |
| --- | --- |
| Apply system changes | `system/setup.sh` |
| Run some steps only | `system/setup.sh <step>...` |
| Apply home changes | `home/setup.sh` |
| Try uncommitted base home changes | `home/setup.sh --local` |
| Pin the overlay to the base's latest commit | commit and push here, then `utils/pin-base.sh` |
| Apply secrets | `secrets/setup.sh` |
| Add or update a secret | `secrets/add.sh <file>...` (commits and pushes the overlay) |
| Update nixpkgs and Home Manager | `nix flake update --flake ./home`, commit, push, then `utils/pin-base.sh` |
| Check the home configuration | `nix flake check ./home`, and `nix flake check ./overlay/home` |
| Format Nix files | `cd home && nix fmt -- flake.nix modules/*.nix` |
| List home generations | `nix run ./home#home-manager -- generations` |
| Roll back the home layer | `<generation path>/activate` |
