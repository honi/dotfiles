#!/usr/bin/env bash
#
# System setup: the base steps, then the overlay's.
#
# Steps are the scripts in steps/, run in name order, in this shell, as root.
# Each step checks the current state, changes only what differs, and ends by
# verifying its result. When an overlay is installed (cloned into overlay/
# in this repo), its system/steps/ run after the base steps, with its
# system/files/ as the files they install. After the last step, installed
# packages are upgraded. When a change needs a reboot, the run offers one at
# the end.
#
# Usage, from your user account (it runs itself again through sudo, which
# asks for your password):
#   ./setup.sh            run every step, then upgrade packages
#   ./setup.sh WORD...    run only the steps whose name (without its number)
#                         starts with one of the words
#
# A failing command stops the run and names the step and line. Run the same
# command again after fixing the cause: completed steps are skipped and the
# run resumes at the step that failed.

set -Eeuo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then exec sudo "$SETUP_DIR/setup.sh" "$@"; fi

OVERLAY_DIR="$(cd "$SETUP_DIR/.." && pwd)/overlay"

# shellcheck source=lib.sh
source "$SETUP_DIR/lib.sh"

trap on_exit EXIT
trap 'fail "line $LINENO of ${BASH_SOURCE[0]##*/}: $BASH_COMMAND"' ERR

# The account the desktop is set up for: the user who called sudo.
TARGET_USER="${SUDO_USER:-}"
[[ -n "$TARGET_USER" && "$TARGET_USER" != root ]] || { echo "run from your user account, not as root" >&2; exit 1; }
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
export TARGET_USER TARGET_HOME

# Layers in order: name and directory with steps/ and files/.
LAYERS=("base:$SETUP_DIR")
if [[ -d "$OVERLAY_DIR/system/steps" ]]; then LAYERS+=("overlay:$OVERLAY_DIR/system"); fi

STEP_FILTER=("$@")

selected() {
  local name="$1" word
  [[ ${#STEP_FILTER[@]} -eq 0 ]] && return 0
  for word in "${STEP_FILTER[@]}"; do
    [[ "$name" == "$word"* || "$name" == [0-9][0-9]-"$word"* ]] && return 0
  done
  return 1
}

state_begin

# Without words, steps completed in an unfinished earlier run are skipped;
# named steps always run.
for layer in "${LAYERS[@]}"; do
  layer_name="${layer%%:*}"
  layer_dir="${layer#*:}"
  FILES_DIR="$layer_dir/files"
  for step in "$layer_dir/steps"/*.sh; do
    [[ -e "$step" ]] || continue
    name="$(basename "$step")"
    id="$layer_name/$name"
    selected "$name" || continue
    if [[ ${#STEP_FILTER[@]} -eq 0 ]] && step_done "$id"; then
      section "$id: completed in an earlier run, skipped"
      continue
    fi
    section "$id"
    CHANGED=0
    # shellcheck source=/dev/null
    source "$step"
    mark_step_done "$id"
  done
done

if [[ ${#STEP_FILTER[@]} -eq 0 ]]; then upgrade_packages; fi

apply_pending
summary

# A full run ends the run's state. So does a run of named steps when no
# unfinished run was being resumed; otherwise the state is left for the
# full run to finish.
if [[ ${#STEP_FILTER[@]} -eq 0 || $RESUMING -eq 0 ]]; then state_finish; fi

offer_reboot
