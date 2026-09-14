# Dotfiles and configurations

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow
package; the desktop package targets `~/.config`.

## Install (fresh EndeavourOS machine)

```sh
git clone <this repo> ~/Dotfiles
~/Dotfiles/setup.sh
```

`setup.sh` installs the packages, disables any competing notification daemon, stows the configs,
enables the services, adds you to the `video` group, and installs the Hyprspace plugin. It is
idempotent — re-run it whenever the package list changes. Log out and back in afterwards (the
`video` group and the Hyprland session both need it).

Every dependency is in `[extra]`; no AUR helper is required.

## Directory structure

```
desktop/            -> ~/.config   (hyprland + quickshell; the only tracked package today)
  hypr/
  quickshell/
hyprland/           kitty, wofi — not yet tracked
shell/              zsh, tmux, oh-my-posh — not yet tracked
text-editor/        nvim, vscode — not yet tracked
```

## desktop/

### hypr

Hyprland >= 0.55 reads `hyprland.lua` directly — the `hl` API is built into Hyprland, there is no
`hyprland.conf` and nothing extra to install for the Lua layer. The config directory is on Lua's
`package.path`, so every `require()` below resolves relative to `~/.config/hypr`.

| File | Role |
|---|---|
| `hyprland.lua` | Entry point. Picks the monitor profile off `/sys/class/dmi/id/chassis_type` (3 = desktop), then look-and-feel, input and autostart. |
| `keybindings.lua` | All binds. Branches on whether `hyprsplit` is loaded, so one file serves both machines. |
| `monitors/desktop.lua` | 3 x 1440p on DP-1/2/3, plus hyprsplit per-monitor workspace blocks. |
| `monitors/laptop.lua` | `eDP-1` plus a catch-all for externals, and lid handling. Deliberately no hyprsplit — see the comment in the file. |
| `theme.lua` | Catppuccin Mocha constants. Only the colours Hyprland actually reads are globals; locals do not survive `require()`. |
| `hyprland-gui.lua` | Written by HyprMod. Don't hand-edit. |
| `hyprsplit/init.lua` | Vendored, see below. |
| `wallpapers/` | Lives in the repo so the path stays machine-independent. |

`hypridle.conf`, `hyprlock.conf` and `hyprpaper.conf` are still hyprlang, since those daemons have
no Lua config.

**hyprsplit** is vendored as a single file. Upstream's repo also builds a deprecated C++ plugin
that this setup does not use, so only `init.lua` is tracked. It carries one local patch — `log()`
writes to stderr instead of stdout. To update:

```sh
curl -L https://raw.githubusercontent.com/shezdy/hyprsplit/main/init.lua \
  -o ~/.config/hypr/hyprsplit/init.lua
# then re-apply the stderr patch and the provenance header at the top of the file
```

**Hyprspace** is an hyprpm plugin, not vendored — `setup.sh` installs it. It backs `SUPER+TAB`.
hyprpm rebuilds it against Hyprland's headers, so run `hyprpm update` after a Hyprland upgrade.

### quickshell

`shell.qml` is the entry point: one `Bar` per monitor, plus the launcher and notification toasts.
`Theme.qml` and `Services.qml` are singletons auto-registered from the config root — moving them
into a subdirectory breaks that.

The config discovers monitors, network device, battery, backlight and audio nodes at runtime, so
there is nothing machine-specific to edit. Cards for hardware that isn't present (battery,
backlight, bluetooth, performance power profile) hide themselves.

It runs the notification server itself, so no other daemon may own
`org.freedesktop.Notifications`.

## Dependencies

- Configuration management: GNU Stow
- Desktop: hyprland, hyprpaper, hypridle, hyprlock, hyprshot, quickshell, kitty, nautilus
- Runtime: pipewire + wireplumber, networkmanager, bluez, upower, power-profiles-daemon, polkit,
  brightnessctl, playerctl, xdg-desktop-portal-hyprland
- Fonts: `ttf-jetbrains-mono-nerd` (**Nerd Fonts v3** — the bar's icons are `nf-md-*` glyphs and
  render as tofu on v2), noto-fonts, noto-fonts-emoji
- Not yet tracked here: zsh + zinit, oh-my-posh, tmux + tpm, gh, asdf, nvim, vscode
