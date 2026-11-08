# Playwright CLI (`playwright-cli`), the browser automation CLI for coding
# agents. Not in nixpkgs, so a script runs it from npm at the exact version
# below (it and the two packages it depends on are exact-pinned, so nothing
# floats); the Node it uses (the LTS) is on the PATH only inside the script.
#
# It uses Playwright's own Chromium (the CLI defaults to Google Chrome), which
# each switch downloads into ~/.cache/ms-playwright at the revision the pinned
# version needs, without the headless shell the CLI doesn't use; nothing is
# downloaded when it is already there.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  script = ".local/bin/playwright-cli";
in
{
  home.file.${script} = {
    executable = true;
    source = pkgs.replaceVars ../files/playwright-cli.sh {
      version = "0.1.23";
      nodejs = pkgs.nodejs_24;
    };
  };

  home.activation.playwrightChromium = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${config.home.homeDirectory}/${script} install-browser chromium --no-shell \
      || echo "playwright-cli: could not install Chromium; run 'playwright-cli install-browser chromium --no-shell'" >&2
  '';
}
