# CLAUDE.md

## Commits

- Make atomic commits: one logical change per commit. Don't commit or push until I confirm. When I say "commit" or "push", do both: commit, then push.
- Use plain imperative commit messages. No `feat:`, `fix:`, `chore:` or other conventional-commit type prefixes.
- Commit changes in whichever repository they belong to: base or overlay.

## Base and overlay

- This repo is public. It's the base install: system and home, with no machines and no hostnames. Never put private details in it (overlay names, private repository URLs, employer details); scripts ask for them.
- An overlay is a private repository cloned into `overlay/` here (gitignored), with the same structure (`system/steps`, `system/files`, `home/modules`, `secrets`, `runbooks`). It holds only config and data, plus a `home/flake.nix` that builds its home configuration with this repo's `lib.mkHome` and pins this repo in its `flake.lock`; every script lives here.
- `overlay/` is gitignored but is a nested repository we work on alongside this one. Always include it when searching (grep, glob, file listings) for a step, module, file, secret or runbook, and look in both base and overlay.
- Prefer overlays that add to base (steps, files, modules, secrets, runbooks) over ones that change what base does. When an overlay has to override something from base, keep it small and say why where it happens.

## Steps and files

- Philosophy: build the system from the ground up, with explicit steps stating what we want. Avoid patches that fix or undo what an earlier step did (purging, masking, overriding). Find the root cause and fix it there, such as the install order, a missing package or the wrong dependency.

- Step numbers order groups, not steps: steps that share a number must not depend on each other. Give a step its own number only when it depends on an earlier group.
- Config files: install whole files from `files/` or use `.d` drop-ins. Don't edit existing files in place with `sed`/`awk`/`>>`. The exception is a file the installer generates that has no drop-in mechanism (`/etc/hosts`): keep one marked block in it with `put_block`.
- Every step, module and file describes only itself: what it does, and why only for real edge cases, kept generic. No references to other steps, modules or docs, and no history of past iterations or fixes.
- Each system step verifies its own result with `verify`. Don't document checks in markdown.
- Steps don't record manual reminders. Manual work goes in `runbooks/`.

## Tooling

- Shell is bash; run `shellcheck` on scripts.
- Format Nix with `nix fmt`, run from `home/` (the flake is there, not at the repo root), and do it before committing any Nix change. If it errors, fix the cause and rerun; don't commit unformatted.

## Local development

- Home Manager changes: apply them locally first with `home/setup.sh --local`, which builds on the files as they are on disk, in both base and overlay, including uncommitted and untracked ones (overriding the pinned base input instead of the commit the overlay's `flake.lock` pins). No `git add` is needed first. Then show me the changes and wait for my confirmation before committing.
- System steps and secrets: never run the setup scripts yourself. I run them.
