# Helpers for setup.sh and its steps.
#
# Writers compare before writing, so running a step twice leaves the system
# as it is. Functions that change something set CHANGED=1, which a step can
# check to run a follow-up command only when needed. Steps don't run
# update-initramfs, update-grub or reboot themselves: they signal it with
# needs_initramfs, needs_grub or needs_reboot, and setup.sh does each once
# at the end.
#
# The run's state lives in STATE_DIR while a run is unfinished: completed
# steps, reboot reasons, pending rebuilds, backups and the kernel decision.
# A failed run keeps it, so the rerun skips completed steps. A finished run
# removes it, together with the backups.

export DEBIAN_FRONTEND=noninteractive

STATE_DIR=/var/lib/dotfiles-setup
CHANGED=0
KERNEL_HELD=()

section() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
log()     { printf '    %s\n' "$*"; }
warn()    { printf '\033[1;33m    warning: %s\033[0m\n' "$*" >&2; }
fail()    { printf '\033[1;31mfailed: %s\033[0m\n' "$*" >&2; exit 1; }

# state -----------------------------------------------------------------------

# Start the run's state, or resume an unfinished run's. Sets RESUMING.
state_begin() {
  if [[ -d "$STATE_DIR" ]]; then
    RESUMING=1
    log "resuming an unfinished run; completed steps are skipped (remove $STATE_DIR to start over)"
  else
    RESUMING=0
    install -d -m 0700 "$STATE_DIR"
  fi
}

# Remove the run's backups, then its state.
state_finish() {
  local backup
  while IFS= read -r backup; do
    if [[ -e "$backup" ]]; then rm -f "$backup"; log "removed backup: $backup"; fi
  done < <(state_list backups)
  rm -rf "$STATE_DIR"
}

step_done()      { [[ -e "$STATE_DIR/done/$1" ]]; }
mark_step_done() { install -d -m 0700 "$STATE_DIR/done/${1%/*}"; touch "$STATE_DIR/done/$1"; }

# state_add LIST LINE: append LINE to a list in the run's state.
state_add() { install -d -m 0700 "$STATE_DIR"; printf '%s\n' "$2" >> "$STATE_DIR/$1"; }

# state_list LIST: print a list, each line once, in the order first added.
state_list() {
  if [[ -f "$STATE_DIR/$1" ]]; then awk '!seen[$0]++' "$STATE_DIR/$1"; fi
}

# signals ---------------------------------------------------------------------

# Record that a change only takes effect after a reboot.
needs_reboot() { state_add reboot "$*"; }

# Record that the initramfs / GRUB menu must be rebuilt (and so, rebooted).
needs_initramfs() { touch "$STATE_DIR/pending-initramfs"; needs_reboot "$*"; }
needs_grub()      { touch "$STATE_DIR/pending-grub"; needs_reboot "$*"; }

# Do the rebuilds steps asked for, once. Also runs from the EXIT trap, so a
# run that fails halfway still applies what earlier steps changed. A rebuild
# that fails stays pending for the next run.
apply_pending() {
  if [[ -e "$STATE_DIR/pending-initramfs" ]]; then
    section "update-initramfs"
    update-initramfs -u -k all
    rm -f "$STATE_DIR/pending-initramfs"
  fi
  if [[ -e "$STATE_DIR/pending-grub" ]]; then
    section "update-grub"
    update-grub
    rm -f "$STATE_DIR/pending-grub"
  fi
}

on_exit() {
  release_kernel_hold
  apply_pending
}

# kernel ----------------------------------------------------------------------

# Record that the kernel update offered in this run was declined.
decline_kernel() { touch "$STATE_DIR/kernel-declined"; }
kernel_declined() { [[ -e "$STATE_DIR/kernel-declined" ]]; }

# Hold every installed kernel package (the metapackage and the versioned
# images) that isn't held already; release_kernel_hold undoes it.
hold_kernel() {
  local pkg
  while IFS= read -r pkg; do
    if ! apt-mark showhold "$pkg" | grep -qx "$pkg"; then
      apt-mark hold "$pkg" >/dev/null
      KERNEL_HELD+=("$pkg")
    fi
  done < <(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-image-*' 2>/dev/null | awk '$1 == "ii" { print $2 }')
}
release_kernel_hold() {
  if [[ ${#KERNEL_HELD[@]} -gt 0 ]]; then
    apt-mark unhold "${KERNEL_HELD[@]}" >/dev/null
    KERNEL_HELD=()
  fi
}

# upgrade ---------------------------------------------------------------------

# Upgrade installed packages. Never removes packages; keeps locally changed
# config files (the package's version is left as .dpkg-dist). A declined
# kernel update stays declined.
upgrade_packages() {
  section "apt-get upgrade"
  if kernel_declined; then
    hold_kernel
    log "kernel held for this upgrade"
  fi
  apt_update
  apt-get upgrade -y -q -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold
  release_kernel_hold
}

# verify ----------------------------------------------------------------------
#
# Each step ends by checking that what it set up is in place. A failed check
# stops the run before the step counts as completed.

# verify DESCRIPTION COMMAND...: run COMMAND (stdout hidden, stderr shown);
# fail the run if it fails.
verify() {
  local desc="$1"
  shift
  if "$@" >/dev/null; then log "verified: $desc"; else fail "verification failed: $desc"; fi
}

is_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
not_installed() { ! is_installed "$1"; }

all_installed() {
  local pkg missing=()
  for pkg in "$@"; do is_installed "$pkg" || missing+=("$pkg"); done
  [[ ${#missing[@]} -eq 0 ]] || { echo "not installed: ${missing[*]}" >&2; return 1; }
}
verify_installed() { verify "installed: $*" all_installed "$@"; }

# backports_current PKG...: the packages are at the version apt would install
# with -t trixie-backports (prints what it would still install otherwise).
backports_current() {
  local plan
  plan="$(apt-get -s -t trixie-backports install "$@")" || return 1
  ! grep '^Inst ' <<<"$plan" >&2
}

# backports_candidate PKG: the version apt would install with
# -t trixie-backports.
backports_candidate() {
  apt-cache -t trixie-backports policy "$1" | awk '$1 == "Candidate:" { print $2 }'
}

# apt_knows_source TEXT: a source whose line in `apt-cache policy` contains
# TEXT (a host or suite) is configured and its index was downloaded.
# (grep without -q reads all of the output: with pipefail, a writer cut off
# by grep exiting early would fail the pipeline.)
apt_knows_source() { apt-cache policy | grep -F "$1" >/dev/null; }

# installed_from PKG TEXT: the installed version of PKG is available from a
# source whose line contains TEXT.
installed_from() {
  apt-cache policy "$1" | awk -v src="$2" '
    /^ \*\*\* / { inst = 1; next }
    /^     [^ ]/ { inst = 0 }
    inst && index($0, src) { found = 1 }
    END { exit !found }'
}

in_group() { id -nG "$1" | tr ' ' '\n' | grep -x "$2" >/dev/null; }

# pam_password_only FILE: FILE doesn't pull in common-auth (which asks for the
# fingerprint) and checks the password with pam_unix.
pam_password_only() {
  ! grep -qE '^@include[[:space:]]+common-auth|pam_fprintd' "$1" && grep -qE '^auth.*pam_unix\.so' "$1"
}

# apt -------------------------------------------------------------------------

apt_update() { apt-get update -q; }

# Install packages that are missing. Installed ones are left as they are;
# the upgrade at the end of the run updates them.
apt_install() {
  local missing=() pkg
  for pkg in "$@"; do
    is_installed "$pkg" || missing+=("$pkg")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    log "installing: ${missing[*]}"
    apt-get install -y -q "${missing[@]}"
  else
    log "already installed: $*"
  fi
}

# Install (or upgrade to) the trixie-backports version of packages.
# -t makes backports the preferred source for this one command only.
apt_install_backports() {
  log "installing from trixie-backports: $*"
  apt-get install -y -q -t trixie-backports "$@"
}

# files -----------------------------------------------------------------------

# write_file PATH [MODE] < content
# Writes stdin to PATH if the content differs. Creates parent directories.
# Feed it with a redirect or heredoc, not a pipe, when CHANGED is needed
# afterwards: a pipe runs it in a subshell, which can't set CHANGED.
write_file() {
  local path="$1" mode="${2:-0644}" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if [[ -f "$path" ]] && cmp -s "$tmp" "$path"; then
    rm -f "$tmp"
    CHANGED=0
    log "unchanged: $path"
  else
    install -D -m "$mode" "$tmp" "$path"
    rm -f "$tmp"
    CHANGED=1
    log "wrote: $path"
  fi
}

# put_file PATH [MODE]
# Installs a whole file from the running step's files/: files/PATH goes to
# PATH (via write_file, so CHANGED is set). Package updates that ship a new
# version of the file show up as .dpkg-dist / .ucf-dist in the summary.
put_file() {
  local path="$1" mode="${2:-0644}"
  write_file "$path" "$mode" < "$FILES_DIR$path"
}

# Copy PATH to PATH.backup before a step replaces it, so the original is at
# hand if the run fails. An existing backup is the original from an earlier
# attempt and is kept. Backups are removed when the run finishes.
backup_once() {
  local path="$1"
  [[ -e "$path.backup" ]] || { cp -a "$path" "$path.backup"; log "backup: $path.backup"; }
  state_add backups "$path.backup"
}

# Download a key and store it de-armored as an apt keyring.
fetch_keyring() {
  local url="$1" dest="$2" tmp
  tmp="$(mktemp)"
  wget -qO- "$url" | gpg --dearmor > "$tmp"
  write_file "$dest" 0644 < "$tmp"
  rm -f "$tmp"
}

# summary ---------------------------------------------------------------------

# Files dpkg or ucf left next to a config file whose package version changed
# while the local copy was changed too: .dpkg-dist / .ucf-dist hold the
# package's new version, .dpkg-old / .ucf-old the local version it replaced.
# Delete each once reconciled.
conffile_leftovers() {
  find /etc -xdev \( -name '*.dpkg-dist' -o -name '*.dpkg-old' -o -name '*.dpkg-new' \
    -o -name '*.ucf-dist' -o -name '*.ucf-old' -o -name '*.ucf-new' \) -print 2>/dev/null | sort
}

REBOOT_REASONS=()

summary() {
  local leftovers=()
  mapfile -t REBOOT_REASONS < <(state_list reboot)
  section "done"
  if [[ ${#REBOOT_REASONS[@]} -gt 0 ]]; then
    log "reboot to apply:"
    printf '      - %s\n' "${REBOOT_REASONS[@]}"
  fi
  mapfile -t leftovers < <(conffile_leftovers)
  if [[ ${#leftovers[@]} -gt 0 ]]; then
    log "package config updates to review (diff against the file without the suffix):"
    printf '      - %s\n' "${leftovers[@]}"
  fi
}

# Offer to reboot when the summary listed reasons to. Only asks from a
# terminal; the answer defaults to no.
offer_reboot() {
  local answer
  [[ ${#REBOOT_REASONS[@]} -gt 0 && -t 0 ]] || return 0
  read -r -p "    reboot now? [y/N] " answer
  if [[ "$answer" == [yY]* ]]; then systemctl reboot; fi
}
