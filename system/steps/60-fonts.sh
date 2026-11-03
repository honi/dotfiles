# Fonts.
#
#   fonts-roboto        Roboto, the UI font (RobotoMono Nerd Font, for
#                       monospace text, the bar and the terminal, comes with
#                       Regolith's Dracula look)
#   fonts-terminus-otb  Terminus in a format GTK and Pango can use (the
#                       console font package only covers the text console),
#                       for the lock screen and session prompts
#

apt_install \
  fonts-roboto \
  fonts-terminus-otb

verify_installed fonts-roboto fonts-terminus-otb
