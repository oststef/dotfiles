import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.gapsOut / 2 + centre.implicitHeight
    color: "transparent"

    // Nothing lives in the bar strip itself any more; the centre module is
    // anchored to the window and everything else moved into the panel.

    // Battery (right). Renders only where there is one, so the bar is unchanged
    // on a desktop. Icon set is the nerd-font battery ramp, 0-10 plus charging.
    Pill {
        id: battery

        readonly property real pct: Services.battery?.percentage ?? 0
        readonly property bool low: !Services.charging && pct <= 0.15

        visible: Services.hasBattery
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapsOut
        y: Theme.gapsOut / 2
        height: centre.implicitHeight

        text: (Services.charging ? "󰂄" : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.round(pct * 10)]) + "  " + Math.round(pct * 100) + "%"
        textColor: low ? Theme.red : Services.charging ? Theme.accent : Theme.fg
        color: Theme.pill

        MouseArea {
            anchors.fill: parent
            onClicked: panel.toggle(3)
        }
    }

    // Centre module: clock always dead-centre, media on the left and
    // notifications on the right slide out of the same pill.
    Item {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gapsOut / 2
        implicitHeight: clock.implicitHeight + 10
        implicitWidth: 0

        property int pad: 22
        // half-width of the always-visible clock section
        readonly property real clockHalf: clock.implicitWidth / 2 + pad
        property real leftW: Services.player ? media.implicitWidth + pad : 0
        property real rightW: Services.notifCount > 0 ? notif.implicitWidth + pad : 0

        Behavior on leftW {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on rightW {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: pill
            x: -centre.clockHalf - centre.leftW
            width: centre.clockHalf * 2 + centre.leftW + centre.rightW
            height: parent.height
            radius: height / 2
            color: Theme.pill
            clip: true
            visible: panel.morph === 0

            // Media indicator (left): animated equaliser + track title
            Row {
                id: media
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                x: centre.leftW - width
                opacity: Math.min(1, centre.leftW / (width + centre.pad))

                Row {
                    spacing: 2
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 3
                            radius: 1
                            height: 4
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on height {
                                running: Services.player?.isPlaying ?? false
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 14
                                    duration: 320 + index * 130
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 4
                                    duration: 320 + index * 130
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: media
                onClicked: panel.toggle(0)
            }

            // Clock (centre)
            Text {
                id: clock
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (centre.leftW - centre.rightW) / 2
                color: Theme.blue
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
                text: Qt.formatDateTime(new Date(), "HH:mm")
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: panel.toggle(1)
                }
            }

            // Notification indicator (right)
            Text {
                id: notif
                anchors.verticalCenter: parent.verticalCenter
                x: pill.width - centre.rightW
                opacity: Math.min(1, centre.rightW / (implicitWidth + centre.pad))
                color: Theme.yellow
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
                text: "󱅫 " + Services.notifCount
                MouseArea {
                    anchors.fill: parent
                    onClicked: panel.toggle(2)
                }
            }
        }
    }

    Panel {
        id: panel
        anchor.window: root
        // anchored to the clock, which is always dead-centre — not to the pill,
        // whose centre shifts as the media/notification sections come and go
        anchor.rect.x: root.width / 2 - width / 2
        anchor.rect.y: centre.y
        startWidth: pill.width
        startHeight: centre.height
        // ...so the morph still grows out of where the pill actually is
        startOffset: pill.x + pill.width / 2
    }
}
