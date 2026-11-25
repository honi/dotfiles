# shellcheck shell=bash
# Activates the devenv environment of the current directory in Claude Code's
# Bash shell. Directories outside a devenv project are left alone; any other
# devenv error is printed and aborts the command.
__devenv_activate() {
  local err env rc=0
  err=$(mktemp)
  env=$(devenv print-dev-env --no-reload --no-tui 2>"$err") || rc=$?
  if [ "$rc" -ne 0 ]; then
    if grep -q 'devenv.nix does not exist' "$err"; then rc=0; else cat "$err" >&2; fi
    rm -f "$err"
    return "$rc"
  fi
  rm -f "$err"
  eval "$env"
}

# Moving within the active project keeps its environment.
cd() {
  builtin cd "$@" || return
  case $PWD/ in "${DEVENV_ROOT:-/nonexistent}"/*) return 0 ;; esac
  __devenv_activate
}

__devenv_activate || exit 1
