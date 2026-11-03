# CLAUDE.md

- Make an atomic commit after each change: one logical change per commit, committed as soon as it's done.
- Use plain imperative commit messages. No `feat:`, `fix:`, `chore:` or other conventional-commit type prefixes.
- This repo is public. It's the base install: system and home, with no machines and no hostnames. Never put private details in it (overlay names, private repository URLs, employer details); scripts ask for them.
- An overlay is a private repository cloned into `overlay/` here (gitignored), with the same structure (`system/steps`, `system/files`, `home/modules`, `secrets`, `runbooks`). It holds only config and data, plus a `home/flake.nix` that builds its home configuration with this repo's `lib.mkHome` and pins this repo in its `flake.lock`; every script lives here.
- Prefer overlays that add to base (steps, files, modules, secrets, runbooks) over ones that change what base does. When an overlay has to override something from base, keep it small and say why where it happens.
- Step numbers order groups, not steps: steps that share a number must not depend on each other. Give a step its own number only when it depends on an earlier group.
- Config files: install whole files from `files/` or use `.d` drop-ins. Don't edit existing files in place with `sed`/`awk`/`>>`.
- Every step, module and file describes only itself: what it does, and why only for real edge cases, kept generic. No references to other steps, modules or docs, and no history of past iterations or fixes.
- Each system step verifies its own result with `verify`. Don't document checks in markdown.
- Steps don't record manual reminders. Manual work goes in `runbooks/`.
- Shell is bash; run `shellcheck` on scripts. Format Nix with `nix fmt`.
