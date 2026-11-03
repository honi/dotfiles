# Audio: PipeWire.
#
# PipeWire is the sound server; it runs per user as systemd user services
# started at login. WirePlumber is its session manager: it picks default
# devices and remembers volumes and choices.
#   pipewire-pulse    serves apps written for PulseAudio
#   pipewire-alsa     routes plain ALSA apps through PipeWire
#   alsa-utils        speaker-test, arecord/aplay for testing
#   pulseaudio-utils  pactl, to query and control the sound server

apt_install \
  pipewire \
  pipewire-pulse \
  pipewire-alsa \
  wireplumber \
  alsa-utils \
  pulseaudio-utils

verify_installed pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils
