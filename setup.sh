#!/usr/bin/env bash
# Bootstrap the Hyprland + Quickshell desktop on a fresh EndeavourOS machine.
# Idempotent: safe to re-run. Everything here is in [extra], no AUR helper needed.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

say() { printf '\n\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }

[[ $EUID -eq 0 ]] && { warn "run as your own user, not root"; exit 1; }

# ---------------------------------------------------------------- packages
# qt6-declarative is not optional: Panel.qml uses QtQuick.Controls MonthGrid,
# DayOfWeekRow, Slider and TextField.
# ttf-jetbrains-mono-nerd must be Nerd Fonts v3 — every icon in the bar is an
# nf-md-* glyph (U+F0000-U+F1AF0). Plain ttf-jetbrains-mono renders pure tofu.
# base-devel/cmake/meson/ninja are for hyprpm compiling Hyprspace below, not
# for the config itself.
say "Installing packages"
sudo pacman -S --needed --noconfirm \
	hyprland hyprpaper hypridle hyprlock hyprshot hyprland-qtutils \
	quickshell qt6-base qt6-declarative qt6-wayland qt6-svg \
	kitty nautilus \
	brightnessctl playerctl \
	pipewire pipewire-pulse pipewire-alsa wireplumber \
	networkmanager bluez bluez-utils upower power-profiles-daemon polkit \
	xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
	ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji hicolor-icon-theme \
	stow git base-devel cmake meson ninja

# ------------------------------------------------- notification bus owner
# Services.qml runs the notification server itself, and only one process can
# own org.freedesktop.Notifications. Don't uninstall anything — just make sure
# nothing else is set to grab the name.
say "Checking for a conflicting notification daemon"
for d in swaync dunst mako; do
	if systemctl --user is-enabled "$d.service" &>/dev/null; then
		warn "$d.service is enabled and will fight quickshell for the notification bus"
		systemctl --user disable --now "$d.service"
	fi
done

# ----------------------------------------------------------------- linking
# Move any pre-existing real directory aside rather than letting stow refuse.
say "Linking configs into $config"
mkdir -p "$config"
for d in hypr quickshell; do
	if [[ -e "$config/$d" && ! -L "$config/$d" ]]; then
		mv "$config/$d" "$config/$d.bak-$(date +%s)"
		warn "moved existing $config/$d aside"
	fi
done
stow -d "$repo" -t "$config" desktop

# ---------------------------------------------------------------- services
say "Enabling services"
sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service
# upower is D-Bus activated; nothing to enable.

# ------------------------------------------------------------------- group
# brightnessctl writes /sys/class/backlight without root only for the video group.
if ! id -nG "$USER" | grep -qw video; then
	say "Adding $USER to the video group (for brightnessctl)"
	sudo usermod -aG video "$USER"
	warn "log out and back in for the video group to take effect"
fi

# ------------------------------------------------------------------ plugin
# keybindings.lua binds SUPER+TAB to hl.plugin.overview.toggle() and
# hyprland.lua configures plugin.overview — both need Hyprspace present.
# hyprpm compiles against the running Hyprland's headers, so this needs an
# active session; skip cleanly when run from a TTY before first login.
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
	say "Installing the Hyprspace plugin"
	hyprpm update
	hyprpm list | grep -q Hyprspace || hyprpm add https://github.com/ImanolBarba/Hyprspace
	hyprpm enable Hyprspace
else
	warn "not inside a Hyprland session — run this afterwards to get SUPER+TAB overview:"
	warn "  hyprpm update && hyprpm add https://github.com/ImanolBarba/Hyprspace && hyprpm enable Hyprspace"
fi

say "Done. Log out and start Hyprland."
