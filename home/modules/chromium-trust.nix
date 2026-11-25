# Makes Chromium-based browsers (Chrome, Chromium, Playwright's Chromium)
# trust the certificates in the system store. They ignore it and read the
# shared NSS database in ~/.pki/nssdb instead, so the database loads p11-kit's
# trust module, which serves the system store. The tools come from the system
# (libnss3-tools) because the module needs the system's libraries.
{
  config,
  lib,
  ...
}:
let
  nssdb = "sql:${config.home.homeDirectory}/.pki/nssdb";
  module = "p11-kit-trust";
  library = "/usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so";
  tools = "/usr/bin";
in
{
  home.activation.chromiumTrust = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${config.home.homeDirectory}/.pki/nssdb/cert9.db" ]; then
      run mkdir -p "${config.home.homeDirectory}/.pki/nssdb"
      run ${tools}/certutil -d ${nssdb} -N --empty-password
    fi
    if ! ${tools}/modutil -dbdir ${nssdb} -list 2>/dev/null | grep -qF "${module}"; then
      run ${tools}/modutil -dbdir ${nssdb} -add ${module} -libfile ${library} -force
    fi
  '';
}
