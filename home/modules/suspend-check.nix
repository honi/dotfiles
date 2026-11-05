# Suspend drain measurement.
#
# Installs `suspend-check` in ~/.local/bin. Run it to suspend the machine and
# print how long it slept, how much of that was deep sleep and the average
# battery drain.
{ ... }:
{
  home.file.".local/bin/suspend-check" = {
    executable = true;
    source = ../files/suspend-check.sh;
  };
}
