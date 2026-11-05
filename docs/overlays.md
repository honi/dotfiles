# Overlays

An overlay is a private repository with what one host adds on top of this base: system steps, home modules, encrypted secrets and its own docs. It's cloned into `overlay/` inside this repo, which git ignores, and the setups pick it up from there. Commit and push it from there like any repository; don't run `git clean -x` here, which would delete it. A host has at most one overlay.

It has the same layout as this repo, and only holds config and data:

```
system/steps/NN-name.sh    run after the base steps
system/files/<path>        files those steps install whole
home/flake.nix             the home configuration: this repo's mkHome with ./modules
home/flake.lock            pins this repo at a commit, and through it nixpkgs and Home Manager
home/modules/default.nix   imported after the base modules
secrets/recipient.txt      the overlay's age public key
secrets/files/<path>.age   encrypted copies of $HOME/<path>
docs/*.md                  manual steps for this host
```

## Keys

Each overlay has two keys, stored as Bitwarden secure notes named after the repository (`<repo>` is its name, as in `git@github.com:OWNER/<repo>.git`):

- **`<repo>-deploy-key`**: a read-only SSH key for the repository only, so a freshly installed host can clone it before any of your own keys are on it.
- **`<repo>-age-key`**: the age key the overlay's secrets are encrypted with. age keys come in pairs: the public key (`age1…`, in `secrets/recipient.txt`, safe to commit) only encrypts; the private key (`AGE-SECRET-KEY-1…`) decrypts. On a host it lives in `~/.config/age/key.txt`.

## Create an overlay

On any computer with this repository, `ssh-keygen` and `age`:

1. Create the private repository on GitHub, with the layout above.
2. Keys: `utils/create-overlay-keys.sh` asks for the repository and prints both keys, each under a header saying where it goes. It writes no files.

3. Home configuration: `home/flake.nix` with this repo as its only input, and `home/modules/default.nix`. Once the overlay is installed, `~/dotfiles/utils/overlay-flake-update.sh` writes and commits its `home/flake.lock`.

   ```nix
   {
     inputs.dotfiles.url = "github:honi/dotfiles?dir=home";
     outputs =
       { dotfiles, ... }:
       let
         homeConfigurations.default = dotfiles.lib.mkHome [ ./modules ];
       in
       {
         inherit homeConfigurations;
         inherit (dotfiles) packages formatter;
         checks.x86_64-linux.default = homeConfigurations.default.activationPackage;
       };
   }
   ```

## Home configuration

The overlay's `home/flake.nix` is the host's home configuration, and its `flake.lock` pins this repo at a commit. Nix only reads files git knows about, so `git add` a new module before running the setup; edits to tracked files apply as they are.

- **Change the overlay's modules:** edit, then `~/dotfiles/home/setup.sh`.
- **Try an uncommitted change to this repo:** `~/dotfiles/home/setup.sh --local`. Nix warns that it won't write that base to the overlay's `flake.lock`.
- **Keep a change to this repo:** commit and push it, then `~/dotfiles/utils/overlay-flake-update.sh` pins the overlay to the latest commit on GitHub, commits the overlay's `flake.lock`, pushes the overlay, and applies. It never pushes this repo; when this checkout's HEAD isn't the commit it pinned, it warns.

## Secrets

Secrets are whole files under `$HOME`, stored encrypted in the overlay and decrypted into place as plain files only you can read.

- **Add or update:** `~/dotfiles/secrets/add.sh <file>...` encrypts each file and commits it on its own, and pushes at the end. The first commit also carries any change to `secrets/recipient.txt`; nothing else staged in the overlay is committed. If the push fails, the commits stay for you to push later.
- **Apply:** `~/dotfiles/secrets/setup.sh` writes every secret whose content differs. A file changed in `$HOME` since it was last written is kept, with a warning: save it with `add.sh`, or delete it and run `setup.sh` again for the overlay's version.
- **Remove:** delete `secrets/files/<path>.age` from the overlay and commit; the file in `$HOME` stays until you delete it.

### Rotate the age key

1. `age-keygen`, as above. Replace the Bitwarden note `<repo>-age-key`, and add the new public key as a second line of `secrets/recipient.txt`.
2. Re-encrypt every secret to both keys: `~/dotfiles/secrets/add.sh` with every secret's file in `$HOME`. The new `recipient.txt` goes in with the first secret's commit.
3. Put the new key in `~/.config/age/key.txt` (or delete the file and run `secrets/setup.sh`, which fetches the note).
4. Remove the old public key from `secrets/recipient.txt` and run `add.sh` on every secret again.
