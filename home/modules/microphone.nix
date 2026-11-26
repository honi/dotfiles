# Default microphone order: the noise-suppressed copy of the best real
# microphone, which is the Logitech BRIO, then the laptop microphone, then a
# Bluetooth headset's.
#
# WirePlumber makes the available source with the highest priority.session
# the default. The BRIO's is raised above the rest, so it's the default while
# plugged in. A Bluetooth headset's microphone would otherwise win over the
# laptop's by a point, and using it switches the headset to its low-quality
# call mode, so its priority is lowered below both.
#
# A microphone with no saved volume starts at 0.512 (0.8 in wpctl, which is
# cubic: 0.8^3, about -6 dB). At full gain the laptop's microphone clips speech.
#
# A PipeWire filter-chain adds "Noise suppressed mic", a copy of the default
# microphone run through the DeepFilterNet plugin, which removes keyboard
# clicks, background noise and some room reverb. Its priority is above the real
# microphones, so it's the default. Its input is the best real microphone:
# PipeWire never links a filter-chain's capture side to its own output.
{ ... }:
{
  xdg.configFile."wireplumber/wireplumber.conf.d/51-microphone-order.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          { node.name = "~alsa_input.usb-046d_Logitech_BRIO_*" }
        ]
        actions = {
          update-props = {
            priority.session = 2500
          }
        }
      }
    ]

    monitor.bluez.rules = [
      {
        matches = [
          { node.name = "~bluez_input.*" }
        ]
        actions = {
          update-props = {
            priority.session = 1000
          }
        }
      }
    ]
  '';

  xdg.configFile."wireplumber/wireplumber.conf.d/51-microphone-volume.conf".text = ''
    wireplumber.settings = {
      device.routes.default-source-volume = 0.512
    }
  '';

  xdg.configFile."pipewire/pipewire.conf.d/51-noise-suppressed-mic.conf".text = ''
    context.modules = [
      {
        name = libpipewire-module-filter-chain
        args = {
          node.description = "Noise suppressed mic"
          media.name = "Noise suppressed mic"
          filter.graph = {
            nodes = [
              {
                type = ladspa
                name = deepfilter
                plugin = /usr/local/lib/ladspa/libdeep_filter_ladspa.so
                label = deep_filter_mono
              }
            ]
          }
          audio.rate = 48000
          capture.props = {
            node.name = "capture.noise_suppressed_mic"
            node.passive = true
            audio.channels = 1
            audio.position = [ MONO ]
          }
          playback.props = {
            node.name = "noise_suppressed_mic"
            media.class = Audio/Source
            priority.session = 3000
            audio.channels = 1
            audio.position = [ MONO ]
          }
        }
      }
    ]
  '';
}
