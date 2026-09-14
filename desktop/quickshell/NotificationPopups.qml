// Toasts for incoming notifications: top-right, under the bar.
// Follows the focused monitor instead of duplicating on every screen.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors.top: true
    anchors.right: true
    // don't reserve screen space; the compositor still keeps us clear of the bar
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: Services.popups.length > 0

    implicitWidth: 380 + Theme.gapsOut * 2
    implicitHeight: Math.max(1, toasts.implicitHeight + Theme.gapsOut)
    // only the toasts swallow clicks, not the whole strip
    mask: Region {
        item: toasts
    }

    ColumnLayout {
        id: toasts
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.gapsIn
        anchors.rightMargin: Theme.gapsOut
        width: 380
        spacing: Theme.gapsIn * 2

        Repeater {
            model: Services.popups

            Rectangle {
                id: toast
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: text.implicitHeight + 20
                radius: 14
                color: Theme.pill
                border.width: 1
                border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.yellow : Theme.muted

                // slide in from the right edge
                property real shown: 0
                opacity: shown
                transform: Translate {
                    x: (1 - toast.shown) * 40
                }
                Component.onCompleted: shown = 1
                Behavior on shown {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                // ponytail: fixed 5s, ignoring the sender's expireTimeout (unit
                // isn't documented). Wire it up if apps need per-notification timing.
                Timer {
                    running: !hover.hovered && toast.modelData.urgency !== NotificationUrgency.Critical
                    interval: 5000
                    onTriggered: Services.dropPopup(toast.modelData)
                }

                HoverHandler {
                    id: hover
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Services.dropPopup(toast.modelData)
                }

                ColumnLayout {
                    id: text
                    x: 12
                    y: 10
                    width: parent.width - 24
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                        text: toast.modelData.appName
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                        text: toast.modelData.summary
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: toast.modelData.body
                        color: Theme.fg
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }
}
