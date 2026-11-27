# Next: a home-built sway desktop

Notes from looking at what Regolith brings and whether to replace it with stock sway, waybar and Home Manager.

## Idle and suspend today

Almost none of these timeouts are configured in this repo. They are Regolith/GNOME defaults.

| When idle | What happens | Where it's set |
|---|---|---|
| 300s | Screen dims to 30% | `regolith-powerd` builds a swayidle command from gsettings: `org.gnome.desktop.session idle-delay=300`, `idle-dim=true`, `idle-brightness=30` |
| 300s | Keyboard backlight off | `home/modules/kbd-backlight.nix`, its own swayidle with a hardcoded `timeout 300` |
| 305s | Screen off (DPMS) | Hardcoded in the powerd swayidle command |
| 310s | Lock with gtklock | Hardcoded in the powerd swayidle command; the command is `wm.program.lock_sway` from `home/modules/lock-screen.nix` |
| 900s | Suspend | gsettings `sleep-inactive-ac-timeout` and `sleep-inactive-battery-timeout`, both 900 with type `suspend` |
| 900s | Suspend when audio stopped while locked | `home/files/audio-sleep-inhibit.sh`, `suspend_after=900`, a copy of the gsettings value |
| 600s | 1Password locks itself | 1Password's own setting |

Around them:

- `home/modules/idle.nix` holds a logind sleep inhibitor while audio plays. It blocks only the 900s suspend.
- `for_window [all] inhibit_idle fullscreen` (a Sway rule in `idle.nix`) blocks every idle step during fullscreen, including the keyboard backlight swayidle.
- No logind drop-ins exist, so logind defaults apply (lid close suspends).
- Two swayidles run independently (Regolith's and the keyboard backlight one), so a stray input event can fire `resume` in one and not the other. The 300 and 900 values are duplicated by hand.
- `kbd-backlight` logs every change to the journal: `journalctl --user -t kbd-backlight`.

## What `regolith-powerd` does

A small Rust daemon started by `regolith-init-powerd.service` from `regolith-wayland.target`. It owns the D-Bus name `org.regolith.powerd`, reads the gsettings above, builds one swayidle command line (dim with `light`, DPMS off and on, lock, `systemctl suspend` or `hibernate`, `playerctl -a pause` before sleep, AC and battery variants through `on_ac_power`) and restarts swayidle when the settings change. It also has some shutdown-prompt strings that duplicate Regolith's sway binding. It handles no lid, power button or battery levels.

It can't be removed alone: `regolith-sway-gsd` depends on it (`regolith-powerd (>= 0.3.0)`), and that is part of `regolith-desktop` and `regolith-session-sway`.

## What Regolith brings

The session starts as `regolith-session-wayland` → sway-regolith → `regolith-wayland.target` units, through `gnome-session`.

| Piece | What it does | Home-built replacement |
|---|---|---|
| `sway-regolith` | Sway build reading settings from a resource database (`set_from_resource`) via `trawld` and `trawlcat` | Stock `sway` and a plain config |
| `trawld`, `trawlcat`, `regolith-look-*`, `regolith-resource-loader` | Xresources-style settings layer, themes, `wm.*` variables | Home Manager options and Nix variables |
| `regolith-powerd` | gsettings to swayidle command | One swayidle service |
| `regolith-displayd` and `kanshi` | Display layout synced into a kanshi config | `kanshi` alone, config from Home Manager |
| `regolith-inputd` | Input settings from gsettings into sway | `input` blocks in the sway config |
| `regolith-sway-gsd` and `gnome-settings-daemon` | Runs gsd-a11y, datetime, housekeeping, print, rfkill, screensaver-proxy, sharing, smartcard, sound | Mostly nothing |
| `gnome-session` units | Orders startup and reaps the session | Sway started directly, with a systemd target Home Manager defines |
| `ilia`, `childe`, `grimshot` | Launcher, next free workspace, screenshots | fuzzel, wofi or rofi-wayland; keep `childe`; `grim` and `slurp` |
| `regolith-rofication` | Notification daemon (Python) | mako or swaync |
| `regolith-avizo` | Volume and brightness popups | Keep avizo, or swayosd |
| `i3status-rs` and bar config | The bar | Waybar |
| `gtklock` | Lock screen | Keep |
| `regolith-sway-clamshell` | Lid-close behavior via `bindswitch` | A sway `bindswitch`, or logind |
| `xdg-desktop-portal-regolith` | Portal backend | `xdg-desktop-portal-wlr` and `-gtk`, already installed |
| `swaybg`, unclutter, touchpad gestures, `regolith-ftue`, `regolith-control-center` | Wallpaper, cursor hiding, gestures, first-run and settings GUI | Sway `output` and `seat` lines; the GUI isn't needed |
| kbd-layout, media keys, workspace config | Sway bindings in `/usr/share/regolith/sway/config.d` | Our own bindings |

Regolith's sway config is 19 files and 326 lines. The real logic is the idle, display, input and session-order pieces; the rest is config lines or packages we can pick ourselves.

## Is it building my own Wayland and sway DE?

Yes. Sway is only the compositor; a desktop environment is that plus the daemons and conventions around it. We'd own:

- **Session start:** how sway launches, which daemons start with it and in what order, and how the environment reaches them.
- **Daemons:** bar, notifications, launcher, idle and lock, display profiles, polkit agent, portals, OSD popups.
- **Policy:** keybindings, theming, timeouts and commands.

No software to write: sway, waybar, mako, kanshi, swayidle, gtklock and fuzzel are existing packages, and Home Manager has options for most (`wayland.windowManager.sway`, `programs.waybar`, `services.mako`, `services.kanshi`, `services.swayidle`). It's a few hundred lines of Nix and config. The ongoing cost is debugging breakage yourself (portals for screen sharing, polkit prompts).

## Would GNOME go entirely?

Mostly yes for the desktop layer, but not entirely.

Stops being used:

- `gnome-session` and its units
- `gnome-settings-daemon` and the `gsd-*` helpers
- `gnome-control-center` and Regolith's settings GUI
- gsettings keys as the place where idle and power settings live

Probably stays:

- GTK and GLib, which Firefox, 1Password, Zoom, gtklock and `xdg-desktop-portal-gtk` link against
- dconf and gsettings as storage for GTK apps (Home Manager sets them through `dconf.settings`)
- `gnome-keyring` (secrets and SSH agent), unless replaced
- `xdg-desktop-portal-gtk` for file dialogs
- NetworkManager, `nm-applet` and `blueman`

Unknown, to check: `evolution-alarm-notify` and `ibus` are running, and we haven't checked what pulled them in. Some tools may expect `gsd-*` over D-Bus (media keys, screensaver inhibit); swayidle and `sway-audio-idle-inhibit` already cover idle.

## Benefits and risks

Benefits:

- Removes the gnome-session and gsettings layer, so each timeout and binding lives once in Home Manager.
- Removes the Regolith apt repo, the plymouth pin, `bc` as an unlisted dependency, and the `mate-polkit` ordering workaround in `system/steps/50-regolith.sh`.
- Continues what we've already replaced (lock screen, idle behavior, theming).

Risks and costs:

- The session start, keybindings and theming (GTK theme, fonts, colors from `regolith-look-dracula`) all need rebuilding.
- The login and system steps (`50-regolith.sh`, `60-lock-screen.sh`) need new steps.
- Overlay modules that read Regolith resources would need checking.
- Debian trixie's `sway` is 1.10.1, the same release as `sway-regolith` (1.10). Regolith's build adds the trawl resource patches, which a plain config doesn't need.

## Suggested plan

Stage it, and keep Regolith as a fallback through a second `wayland-sessions` entry until the new session is solid.

1. Replace `regolith-powerd` with one swayidle service in `home/modules/idle.nix`: dim, DPMS, lock, suspend and the keyboard backlight in one place, with the timeouts defined once and `audio-sleep-inhibit` reading them. Needs an override or masking of the Regolith unit, since the package can't be removed alone.
2. Take over displays and input: `kanshi` config and sway `input` blocks from Home Manager.
3. Replace the session: stock sway, waybar, mako, a launcher, polkit agent and portals, with a systemd target tying them together.
4. Drop the Regolith packages and the system steps that exist only for them.

Open question before step 1: whether to override the unit or move straight to step 3.
