#!/usr/bin/env bash
#
# Run the Playwright CLI at a pinned version.
#
# Installs @playwright/cli once into ~/.cache/playwright-cli/<version> (install
# scripts off, own npm cache) and runs it with node directly, not through npx:
# Playwright warns about npx-run installs. Node is on the PATH only here, so
# `node`, `npm` and `npx` stay out of the shell. Uses Playwright's Chromium
# unless PLAYWRIGHT_MCP_BROWSER says otherwise.

set -euo pipefail

version=@version@
export PATH="@nodejs@/bin:$PATH"

base="${XDG_CACHE_HOME:-$HOME/.cache}/playwright-cli"
dir="$base/$version"
export npm_config_cache="$base/npm"
export npm_config_ignore_scripts=true
export PLAYWRIGHT_MCP_BROWSER="${PLAYWRIGHT_MCP_BROWSER:-chromium}"

if [ ! -d "$dir" ]; then
  mkdir -p "$base"
  tmp="$(mktemp -d "$base.XXXXXX")"
  npm install --prefix "$tmp" --no-audit --no-fund --loglevel=error "@playwright/cli@$version"
  mv "$tmp" "$dir"
fi

exec node "$dir/node_modules/@playwright/cli/playwright-cli.js" "$@"
