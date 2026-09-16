// App launcher. Replaces wofi --show drun; bound to SUPER+space via the
// hyprland global shortcut registered below.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import "fuzzy.js" as Fuzzy

PanelWindow {
    id: root

    property bool opened: false

    // follow the focused monitor instead of opening on every screen
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        onPressed: root.opened = !root.opened
    }

    // full screen so a click anywhere outside the box closes us
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: opened || morph > 0
    color: "transparent"

    // same open/close morph as the top panel: 0 = pill, 1 = full box
    property real morph: opened ? 1 : 0
    Behavior on morph {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    onOpenedChanged: {
        if (opened) {
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    function launch() {
        const entry = root.results[list.currentIndex];
        if (entry)
            entry.execute();
        root.opened = false;
    }

    readonly property var results: {
        const q = search.text;
        // an empty query scores every entry 0, so the sort falls through to alphabetical
        return DesktopEntries.applications.values.filter(a => !a.noDisplay).map(a => ({
                    entry: a,
                    score: Fuzzy.scoreEntry(q, a)
                })).filter(x => isFinite(x.score)).sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name)).slice(0, 50).map(x => x.entry);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.opened = false
    }

    Rectangle {
        id: box
        // the size the morph starts from, and the one it ends at
        readonly property real startW: 240
        readonly property real startH: 48
        readonly property real fullW: 560
        property real fullH: 64 + list.height + (list.height > 0 ? 8 : 0)
        Behavior on fullH {
            enabled: root.morph === 1
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        x: (parent.width - width) / 2
        y: parent.height / 5
        width: startW + (fullW - startW) * root.morph
        height: startH + (fullH - startH) * root.morph

        // one list row; the box height snaps to whole rows so none is half-cut
        readonly property int rowHeight: 52
        radius: Math.min(height / 2, 18)
        clip: true
        color: Theme.pill
        border.width: 1
        border.color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, root.morph)

        // swallow clicks on the box so they don't reach the backdrop
        MouseArea {
            anchors.fill: parent
        }

        TextInput {
            id: search
            x: 20
            width: box.fullW - 40
            height: 64
            opacity: Math.min(1, root.morph * 1.5)
            verticalAlignment: TextInput.AlignVCenter
            focus: true
            color: Theme.fg
            selectionColor: Theme.blue
            selectedTextColor: Theme.bg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            onTextChanged: list.currentIndex = 0

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: search.text === ""
                text: "󰍉  search"
                color: Theme.muted
                font: search.font
            }

            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onDownPressed: list.currentIndex = Math.min(root.results.length - 1, list.currentIndex + 1)
            Keys.onEscapePressed: root.opened = false
            Keys.onReturnPressed: root.launch()
            Keys.onEnterPressed: root.launch()
        }

        ListView {
            id: list
            y: 64
            width: box.fullW
            opacity: Math.min(1, root.morph * 1.5)
            // grows with the list, then scrolls — always a whole number of rows
            height: Math.min(contentHeight, parent.rowHeight * 8)
            clip: true
            model: root.results
            currentIndex: 0
            highlightMoveDuration: 100
            keyNavigationEnabled: false

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: list.parent.rowHeight
                color: list.currentIndex === index ? Theme.bg : "transparent"

                IconImage {
                    id: icon
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 32
                    source: Quickshell.iconPath(modelData.icon, true)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 20
                    visible: icon.source == ""
                    text: "󰣆"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                }

                Column {
                    x: 68
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.name
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: text !== ""
                        text: modelData.genericName || modelData.comment
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: list.currentIndex = index
                    onClicked: root.launch()
                }
            }
        }
    }
}
