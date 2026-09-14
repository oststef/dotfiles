pragma Singleton

import Quickshell
import QtQuick

// Catppuccin Mocha, same palette Hyprland uses (~/.config/hypr/theme.lua).
// accent = green, matching hyprland's active_border.
Singleton {
    readonly property color bg: "#1e1e2e"      // base — inset cards
    readonly property color pill: "#313244"    // surface0 — bar/panel surface
    readonly property color fg: "#cdd6f4"      // text
    readonly property color muted: "#6c7086"   // overlay0
    readonly property color accent: "#a6e3a1"  // green
    readonly property color blue: "#89b4fa"
    readonly property color yellow: "#f9e2af"
    readonly property color red: "#f38ba8"
    // Match Hyprland general:gaps_out / gaps_in
    readonly property int gapsOut: 20
    readonly property int gapsIn: 5
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
}
