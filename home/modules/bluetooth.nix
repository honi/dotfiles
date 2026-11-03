# Bluetooth file transfer service (obexd), started on demand by blueman.
#
# Its contact-server plugins (pbap, irmc) share an Evolution address book
# back-end whose setup blocks obexd for about 25 seconds on a cold start, so
# blueman's first call to it times out and its tray icon appears that late.
# The same setup can also stop obexd from registering file receive at all.
# Without the two plugins obexd answers at once.
#
# Lost: other devices reading this laptop's contacts (Phonebook Access
# server) and IrMC sync. File send/receive, file browsing, message access and
# reading a phone's contacts (Phonebook Access client) still work.
#
# Remove once Debian's bluez-obexd includes the upstream fix (5.88).
{ ... }:
{
  xdg.configFile."systemd/user/obex.service.d/no-phonebook.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=/usr/libexec/bluetooth/obexd --noplugin=pbap,irmc
  '';
}
