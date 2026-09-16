// Expanded panel: tabbed media / calendar / notifications.
// Opens under the centre pill on the tab matching whatever was clicked.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import QtQuick.Layouts

PopupWindow {
    id: panel

    // -1 closed, 0 media, 1 clock/calendar, 2 notifications, 3 settings, 4 power
    property int tab: -1
    // size the morph starts from: the bar pill it grows out of
    property real startWidth: 0
    property real startHeight: 0
    // pill centre relative to the panel centre, so the morph starts on the pill
    property real startOffset: 0

    function toggle(t) {
        tab = tab === t ? -1 : t;
    }
    implicitWidth: 380
    implicitHeight: content.implicitHeight + 32
    Behavior on implicitHeight {
        enabled: panel.morph === 1
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    visible: tab >= 0 || morph > 0
    color: "transparent"

    // 0 = still the bar pill, 1 = fully open panel
    property real morph: tab >= 0 ? 1 : 0
    Behavior on morph {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    // clicking anywhere else closes it
    HyprlandFocusGrab {
        windows: [panel]
        active: panel.tab >= 0
        onCleared: panel.tab = -1
    }

    property date now: new Date()
    // month currently shown, as an offset from the real one
    property int monthOffset: 0
    onVisibleChanged: if (visible)
        monthOffset = 0
    Timer {
        interval: 1000
        running: panel.visible
        repeat: true
        onTriggered: panel.now = new Date()
    }
    readonly property date shown: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)

    Rectangle {
        id: morphBox
        readonly property real startW: panel.startWidth
        readonly property real startH: panel.startHeight
        x: ((parent.width - startW) / 2 + panel.startOffset) * (1 - panel.morph)
        y: 0
        width: startW + (parent.width - startW) * panel.morph
        height: startH + (parent.height - startH) * panel.morph
        radius: Math.min(height / 2, 18)
        clip: true
        color: Theme.pill
        border.width: 1
        border.color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, panel.morph)

        ColumnLayout {
            id: content
            x: 16
            y: 16
            width: panel.width - 32
            height: implicitHeight
            opacity: Math.min(1, panel.morph * 1.5)
            spacing: 14

            // Tab bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ["󰝚", "󰃭", "󱅫", "󰒓", "󰐥"]
                    Pill {
                        required property int index
                        required property string modelData
                        readonly property bool current: panel.tab === index
                        Layout.fillWidth: true
                        implicitHeight: 38
                        text: modelData
                        textColor: current ? Theme.bg : Theme.muted
                        color: current ? Theme.accent : Theme.bg
                        padding: 10
                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.tab = parent.index
                        }
                    }
                }
            }

            // ── Media ──
            ColumnLayout {
                Layout.fillWidth: true
                visible: panel.tab === 0
                spacing: 12

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 160
                    implicitHeight: 160
                    radius: 12
                    color: Theme.bg
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: Services.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !(Services.player?.trackArtUrl)
                        text: "󰝚"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 56
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: Services.player?.trackTitle ?? "nothing playing"
                        color: Services.player ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        visible: Services.player !== null
                        text: Services.player?.trackArtist ?? ""
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }

                // transport, centred under the whole header
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    visible: Services.player !== null
                    Pill {
                        implicitWidth: 34
                        implicitHeight: 34
                        text: "󰒮"
                        textColor: Theme.fg
                        color: Theme.bg
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (Services.player?.canGoPrevious)
                                Services.player.previous()
                        }
                    }
                    Pill {
                        implicitWidth: 42
                        implicitHeight: 42
                        text: Services.player?.isPlaying ? "󰏤" : "󰐊"
                        textColor: Theme.bg
                        color: Theme.accent
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (Services.player?.canTogglePlaying)
                                Services.player.togglePlaying()
                        }
                    }
                    Pill {
                        implicitWidth: 34
                        implicitHeight: 34
                        text: "󰒭"
                        textColor: Theme.fg
                        color: Theme.bg
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (Services.player?.canGoNext)
                                Services.player.next()
                        }
                    }
                }
            }

            // ── Clock / calendar ──
            ColumnLayout {
                Layout.fillWidth: true
                visible: panel.tab === 1
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(panel.now, "HH:mm:ss")
                        color: Theme.blue
                        font.family: Theme.fontFamily
                        font.pixelSize: 34
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(panel.now, "dddd, d MMMM yyyy")
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                // Month header + navigation
                RowLayout {
                    Layout.fillWidth: true
                    Pill {
                        text: "‹"
                        textColor: Theme.fg
                        color: Theme.bg
                        padding: 10
                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.monthOffset--
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDate(panel.shown, "MMMM yyyy")
                        color: Theme.yellow
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Pill {
                        text: "›"
                        textColor: Theme.fg
                        color: Theme.bg
                        padding: 10
                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.monthOffset++
                        }
                    }
                }

                DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: grid.locale
                    delegate: Text {
                        text: shortName
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MonthGrid {
                    id: grid
                    Layout.fillWidth: true
                    month: panel.shown.getMonth()
                    year: panel.shown.getFullYear()
                    spacing: 2
                    delegate: Rectangle {
                        implicitWidth: 34
                        implicitHeight: 28
                        radius: 8
                        readonly property bool isToday: model.today
                        color: isToday ? Theme.blue : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: parent.isToday ? Theme.bg : (model.month === grid.month ? Theme.fg : Theme.muted)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: parent.isToday
                        }
                    }
                }
            }

            // ── Notifications ──
            ColumnLayout {
                Layout.fillWidth: true
                visible: panel.tab === 2
                spacing: 8

                // not a RowLayout: clear is anchored out of the flow so the
                // header stays centred on the panel whether or not it's there
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(header.implicitHeight, clear.implicitHeight)

                    Text {
                        id: header
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Services.notifCount === 0 ? "󱅫  no notifications" : "󱅫  " + Services.notifCount + (Services.notifCount === 1 ? " notification" : " notifications")
                        color: Services.notifCount === 0 ? Theme.muted : Theme.yellow
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    Pill {
                        id: clear
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Services.notifCount > 0
                        text: "clear"
                        textColor: Theme.fg
                        color: Theme.bg
                        padding: 10
                        MouseArea {
                            anchors.fill: parent
                            // copy first: dismissing mutates the model we'd be iterating
                            onClicked: [...Services.notifications.values].forEach(n => n.dismiss())
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    // grows with the list, then scrolls
                    Layout.preferredHeight: Math.min(contentHeight, 300)
                    visible: Services.notifCount > 0
                    clip: true
                    spacing: 6
                    model: Services.notifications

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        implicitHeight: body.implicitHeight + 16
                        radius: 8
                        color: Theme.bg

                        ColumnLayout {
                            id: body
                            x: 10
                            y: 8
                            width: parent.width - 20 - close.width
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text !== ""
                                text: [modelData.appName, Services.notifTime(modelData)].filter(s => s).join("  ·  ")
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 4
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text !== ""
                                text: modelData.summary
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: modelData.body
                                color: Theme.fg
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }

                        Text {
                            id: close
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            text: "󰅖"
                            color: closeArea.containsMouse ? Theme.yellow : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                onClicked: modelData.dismiss()
                            }
                        }
                    }
                }
            }

            // ── Settings ──
            ColumnLayout {
                id: settings
                Layout.fillWidth: true
                visible: panel.tab === 3
                spacing: 8

                readonly property var audio: Services.sink?.audio ?? null
                readonly property bool online: Services.wifiNetwork !== null || Services.wired

                // Battery. Absent on a desktop, so the whole card drops out.
                Rectangle {
                    id: batCard
                    Layout.fillWidth: true
                    visible: Services.hasBattery
                    implicitHeight: 62
                    radius: 16
                    color: Theme.bg

                    readonly property real pct: Services.battery?.percentage ?? 0
                    // seconds; 0 when UPower has no estimate yet
                    readonly property real secs: Services.charging ? (Services.battery?.timeToFull ?? 0) : (Services.battery?.timeToEmpty ?? 0)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Pill {
                            implicitWidth: 38
                            implicitHeight: 38
                            hoverable: false
                            text: Services.charging ? "󰂄" : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.round(batCard.pct * 10)]
                            textColor: Theme.bg
                            color: !Services.charging && batCard.pct <= 0.15 ? Theme.red : Theme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: Math.round(batCard.pct * 100) + "%"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: batCard.secs <= 0 ? (Services.charging ? "charging" : "on battery") : Math.floor(batCard.secs / 3600) + "h " + Math.floor(batCard.secs % 3600 / 60) + "m " + (Services.charging ? "to full" : "left")
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                }

                // Power profile. power-profiles-daemon; performance isn't
                // offered on every machine.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            {
                                icon: "󰾆",
                                p: PowerProfile.PowerSaver
                            },
                            {
                                icon: "󰾅",
                                p: PowerProfile.Balanced
                            },
                            {
                                icon: "󰓅",
                                p: PowerProfile.Performance
                            }
                        ]
                        Pill {
                            required property var modelData
                            readonly property bool current: PowerProfiles.profile === modelData.p
                            visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                            Layout.fillWidth: true
                            implicitHeight: 34
                            padding: 6
                            text: modelData.icon
                            textColor: current ? Theme.bg : Theme.muted
                            color: current ? Theme.accent : Theme.bg
                            MouseArea {
                                anchors.fill: parent
                                onClicked: PowerProfiles.profile = parent.modelData.p
                            }
                        }
                    }
                }

                // Network: tap the header to expand into a picker.
                Rectangle {
                    id: netCard
                    Layout.fillWidth: true
                    implicitHeight: net.implicitHeight + 24
                    radius: 16
                    color: Theme.bg
                    clip: true

                    property bool expanded: false
                    // scan only while someone is looking at the list
                    readonly property bool scanning: expanded && panel.tab === 3 && panel.visible
                    onScanningChanged: if (Services.wifiDevice)
                        Services.wifiDevice.scannerEnabled = scanning
                    // last connect failure, cleared on the next attempt
                    property string error: ""

                    readonly property var visibleNetworks: {
                        const n = Services.wifiDevice?.networks?.values ?? [];
                        return [...n].sort((a, b) => (b.signalStrength ?? 0) - (a.signalStrength ?? 0));
                    }

                    ColumnLayout {
                        id: net
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 10

                        RowLayout {
                            id: netHeader
                            Layout.fillWidth: true
                            spacing: 12

                            Pill {
                                implicitWidth: 38
                                implicitHeight: 38
                                hoverable: false
                                text: Services.wifiNetwork ? "󰖩" : Services.wired ? "󰈀" : "󰖪"
                                textColor: settings.online ? Theme.bg : Theme.fg
                                color: settings.online ? Theme.accent : Theme.pill
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: Services.wifiNetwork ? "wi-fi" : Services.wired ? "wired" : "network"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: netCard.error !== "" ? netCard.error : (Services.wifiNetwork?.name ?? (Services.wired ? "connected" : "offline"))
                                    color: netCard.error !== "" ? Theme.red : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }

                            Text {
                                visible: Services.wifiDevice !== undefined
                                text: netCard.expanded ? "󰅃" : "󰅀"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        // radio toggle
                        RowLayout {
                            Layout.fillWidth: true
                            visible: netCard.expanded
                            Text {
                                Layout.fillWidth: true
                                text: Networking.wifiHardwareEnabled ? "wi-fi radio" : "blocked by rfkill"
                                color: Networking.wifiHardwareEnabled ? Theme.fg : Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                            }
                            Pill {
                                implicitHeight: 28
                                padding: 10
                                text: Networking.wifiEnabled ? "on" : "off"
                                textColor: Networking.wifiEnabled ? Theme.bg : Theme.fg
                                color: Networking.wifiEnabled ? Theme.accent : Theme.pill
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: Networking.wifiHardwareEnabled
                                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 260)
                            visible: netCard.expanded && Networking.wifiEnabled
                            clip: true
                            spacing: 4
                            model: netCard.visibleNetworks

                            delegate: Rectangle {
                                id: row
                                required property var modelData
                                width: ListView.view.width
                                implicitHeight: rowCol.implicitHeight + 12
                                radius: 8
                                color: modelData.connected ? Theme.pill : "transparent"

                                // Open networks and saved ones connect straight
                                // away; anything else needs a PSK typed in.
                                readonly property bool needsPsk: !modelData.known && modelData.security !== WifiSecurityType.Open
                                property bool askingPsk: false

                                Connections {
                                    target: row.modelData
                                    function onConnectionFailed(reason) {
                                        netCard.error = row.modelData.name + ": " + ConnectionFailReason.toString(reason);
                                    }
                                }

                                // behind the content: the labels are Text and
                                // let clicks through, the pills and field don't
                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    onClicked: {
                                        netCard.error = "";
                                        if (row.modelData.connected) {
                                            row.modelData.requestDisconnect();
                                        } else if (row.needsPsk) {
                                            row.askingPsk = !row.askingPsk;
                                            if (row.askingPsk)
                                                psk.forceActiveFocus();
                                        } else {
                                            row.modelData.requestConnect();
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: rowCol
                                    x: 8
                                    y: 6
                                    width: parent.width - 16
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            // four bars, floor of signal strength
                                            text: ["󰤟", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor((row.modelData.signalStrength ?? 0) / 25))]
                                            color: row.modelData.connected ? Theme.accent : Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: row.modelData.name
                                            color: row.modelData.connected ? Theme.accent : Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize - 1
                                            font.bold: row.modelData.connected
                                        }
                                        Text {
                                            visible: row.modelData.security !== WifiSecurityType.Open
                                            text: "󰌾"
                                            color: Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize - 3
                                        }
                                        Text {
                                            visible: row.modelData.stateChanging
                                            text: "…"
                                            color: Theme.yellow
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                        }
                                        Pill {
                                            visible: row.modelData.known
                                            implicitHeight: 24
                                            padding: 8
                                            text: "forget"
                                            textColor: Theme.muted
                                            color: Theme.bg
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: row.modelData.requestForget()
                                            }
                                        }
                                    }

                                    // PSK entry, only for an unknown secured network
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: row.askingPsk
                                        spacing: 6
                                        TextField {
                                            id: psk
                                            Layout.fillWidth: true
                                            echoMode: TextInput.Password
                                            placeholderText: "password"
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize - 2
                                            background: Rectangle {
                                                radius: 8
                                                color: Theme.bg
                                                border.width: 1
                                                border.color: Theme.muted
                                            }
                                            onAccepted: {
                                                netCard.error = "";
                                                row.modelData.connectWithPsk(text);
                                                row.askingPsk = false;
                                                text = "";
                                            }
                                        }
                                        Pill {
                                            implicitHeight: 28
                                            padding: 10
                                            text: "join"
                                            textColor: Theme.bg
                                            color: Theme.accent
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: psk.accepted()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // only the header row toggles; the list below keeps its own
                    // clicks, so this can't just fill the card
                    MouseArea {
                        x: net.x + netHeader.x
                        y: net.y + netHeader.y
                        width: netHeader.width
                        height: netHeader.height
                        enabled: Services.wifiDevice !== undefined
                        onClicked: netCard.expanded = !netCard.expanded
                    }
                }


                // Bluetooth: same expand-to-pick shape as the network card.
                // Hidden when bluetoothd isn't running — no adapter to talk to.
                Rectangle {
                    id: btCard
                    Layout.fillWidth: true
                    visible: btCard.adapter !== null
                    implicitHeight: bt.implicitHeight + 24
                    radius: 16
                    color: Theme.bg
                    clip: true

                    readonly property var adapter: Bluetooth.defaultAdapter
                    property bool expanded: false
                    // discover only while someone is looking at the list
                    readonly property bool scanning: expanded && panel.tab === 3 && panel.visible && (btCard.adapter?.enabled ?? false)
                    onScanningChanged: if (btCard.adapter)
                        btCard.adapter.discovering = scanning

                    readonly property var connectedDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
                    // connected, then paired, then whatever else is in range
                    readonly property var visibleDevices: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

                    ColumnLayout {
                        id: bt
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 10

                        RowLayout {
                            id: btHeader
                            Layout.fillWidth: true
                            spacing: 12

                            Pill {
                                implicitWidth: 38
                                implicitHeight: 38
                                hoverable: false
                                text: btCard.adapter?.enabled ? "󰂯" : "󰂲"
                                textColor: btCard.connectedDevice ? Theme.bg : Theme.fg
                                color: btCard.connectedDevice ? Theme.accent : Theme.pill
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: "bluetooth"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: btCard.connectedDevice?.name ?? (btCard.adapter?.enabled ? "not connected" : "off")
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }

                            Text {
                                text: btCard.expanded ? "󰅃" : "󰅀"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        // radio toggle
                        RowLayout {
                            Layout.fillWidth: true
                            visible: btCard.expanded
                            Text {
                                Layout.fillWidth: true
                                text: btCard.adapter?.discovering ? "scanning…" : "bluetooth radio"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                            }
                            Pill {
                                implicitHeight: 28
                                padding: 10
                                text: btCard.adapter?.enabled ? "on" : "off"
                                textColor: btCard.adapter?.enabled ? Theme.bg : Theme.fg
                                color: btCard.adapter?.enabled ? Theme.accent : Theme.pill
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: btCard.adapter.enabled = !btCard.adapter.enabled
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 260)
                            visible: btCard.expanded && (btCard.adapter?.enabled ?? false)
                            clip: true
                            spacing: 4
                            model: btCard.visibleDevices

                            delegate: Rectangle {
                                id: btRow
                                required property var modelData
                                width: ListView.view.width
                                implicitHeight: 34
                                radius: 8
                                color: modelData.connected ? Theme.pill : "transparent"

                                // an unpaired device has to be paired first;
                                // bluez connects it as part of pairing
                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    onClicked: {
                                        if (btRow.modelData.connected)
                                            btRow.modelData.disconnect();
                                        else if (btRow.modelData.pairing)
                                            btRow.modelData.cancelPair();
                                        else if (btRow.modelData.paired)
                                            btRow.modelData.connect();
                                        else
                                            btRow.modelData.pair();
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: ({
                                            "audio-headset": "󰋋",
                                            "audio-headphones": "󰋋",
                                            "audio-card": "󰓃",
                                            "input-keyboard": "󰌌",
                                            "input-mouse": "󰍽",
                                            "input-gaming": "󰊴",
                                            "phone": "󰄜",
                                            "computer": "󰟀"
                                        })[btRow.modelData.icon] ?? "󰂱"
                                        color: btRow.modelData.connected ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: btRow.modelData.name
                                        color: btRow.modelData.connected ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 1
                                        font.bold: btRow.modelData.connected
                                    }
                                    Text {
                                        visible: btRow.modelData.batteryAvailable
                                        text: Math.round((btRow.modelData.battery ?? 0) * 100) + "%"
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                    Text {
                                        visible: btRow.modelData.pairing || btRow.modelData.state === BluetoothDeviceState.Connecting || btRow.modelData.state === BluetoothDeviceState.Disconnecting
                                        text: "…"
                                        color: Theme.yellow
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                    }
                                    Pill {
                                        visible: btRow.modelData.paired
                                        implicitHeight: 24
                                        padding: 8
                                        text: "forget"
                                        textColor: Theme.muted
                                        color: Theme.bg
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: btRow.modelData.forget()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // header row only, same reason as the network card
                    MouseArea {
                        x: bt.x + btHeader.x
                        y: bt.y + btHeader.y
                        width: btHeader.width
                        height: btHeader.height
                        onClicked: btCard.expanded = !btCard.expanded
                    }
                }

                // card, like the rows in the reference: label + fat slider,
                // expanding into the output/input device pickers
                Rectangle {
                    id: soundCard
                    Layout.fillWidth: true
                    implicitHeight: sound.implicitHeight + 24
                    radius: 16
                    color: Theme.bg
                    clip: true

                    property bool expanded: false

                    ColumnLayout {
                        id: sound
                        x: 14
                        y: 12
                        width: parent.width - 28
                        spacing: 10

                        RowLayout {
                            id: soundHeader
                            Layout.fillWidth: true
                            spacing: 8
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: "sound"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: Services.sink?.description ?? "no output"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }
                            Text {
                                text: Math.round((settings.audio?.volume ?? 0) * 100) + "%"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                            Text {
                                text: soundCard.expanded ? "󰅃" : "󰅀"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Slider {
                                id: volume
                                Layout.fillWidth: true
                                implicitHeight: 34
                                enabled: settings.audio !== null
                                value: settings.audio?.volume ?? 0
                                onMoved: settings.audio.volume = value
                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Theme.pill
                                    Rectangle {
                                        // never shorter than the icon it holds
                                        width: Math.max(parent.height, volume.visualPosition * parent.width)
                                        height: parent.height
                                        radius: parent.radius
                                        color: settings.audio?.muted ? Theme.muted : Theme.accent
                                    }
                                    Text {
                                        x: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: settings.audio?.muted ? "󰝟" : "󰕾"
                                        color: Theme.bg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                    }
                                }
                                // the whole groove is draggable; no knob in this style
                                handle: Item {}
                            }

                            Pill {
                                implicitWidth: 34
                                implicitHeight: 34
                                text: settings.audio?.muted ? "󰖁" : "󰕾"
                                textColor: settings.audio?.muted ? Theme.bg : Theme.fg
                                color: settings.audio?.muted ? Theme.red : Theme.pill
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (settings.audio)
                                        settings.audio.muted = !settings.audio.muted
                                }
                            }
                        }

                        // Device pickers. Both lists use the same row, which
                        // tells outputs from inputs by the node itself.
                        Repeater {
                            model: soundCard.expanded ? [
                                {
                                    label: "output",
                                    nodes: Services.sinks
                                },
                                {
                                    label: "input",
                                    nodes: Services.sources
                                }
                            ] : []

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: parent.modelData.label
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 3
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.min(contentHeight, 180)
                                    clip: true
                                    spacing: 2
                                    model: parent.modelData.nodes

                                    delegate: Rectangle {
                                        id: devRow
                                        required property var modelData
                                        readonly property bool current: modelData === (modelData.isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource)
                                        width: ListView.view.width
                                        implicitHeight: 30
                                        radius: 8
                                        color: current ? Theme.pill : "transparent"

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (devRow.modelData.isSink)
                                                    Pipewire.preferredDefaultAudioSink = devRow.modelData;
                                                else
                                                    Pipewire.preferredDefaultAudioSource = devRow.modelData;
                                            }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8
                                            Text {
                                                text: devRow.modelData.isSink ? "󰓃" : "󰍬"
                                                color: devRow.current ? Theme.accent : Theme.fg
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSize - 1
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                text: devRow.modelData.description || devRow.modelData.name
                                                color: devRow.current ? Theme.accent : Theme.fg
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSize - 2
                                                font.bold: devRow.current
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // header row only, so the lists keep their own clicks
                    MouseArea {
                        x: sound.x + soundHeader.x
                        y: sound.y + soundHeader.y
                        width: soundHeader.width
                        height: soundHeader.height
                        onClicked: soundCard.expanded = !soundCard.expanded
                    }
                }

                // Brightness. Quickshell has no backlight service, so this goes
                // through brightnessctl -m, which reports whatever the device is
                // actually called (intel_backlight, amdgpu_bl0, ...) rather than
                // us guessing a sysfs path. Hidden when there is no backlight.
                Rectangle {
                    id: backlight
                    Layout.fillWidth: true
                    visible: pct >= 0
                    implicitHeight: light.implicitHeight + 24
                    radius: 16
                    color: Theme.bg

                    // -1 until brightnessctl answers; stays -1 with no backlight
                    property real pct: -1

                    // brightnessctl -m: device,class,current,percent%,max
                    Process {
                        id: readBrightness
                        command: ["brightnessctl", "-m"]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const f = text.trim().split("\n")[0]?.split(",") ?? [];
                                backlight.pct = f.length >= 4 ? parseInt(f[3]) / 100 : -1;
                            }
                        }
                    }
                    Process {
                        id: setBrightness
                    }
                    function apply() {
                        setBrightness.running = false;
                        setBrightness.command = ["brightnessctl", "set", Math.round(backlight.pct * 100) + "%"];
                        setBrightness.running = true;
                    }
                    // A drag emits onMoved per mouse move; one brightnessctl per
                    // sample is ~60 fork+execs a second and the slider goes sticky.
                    Timer {
                        interval: 50
                        repeat: true
                        running: brightness.pressed
                        triggeredOnStart: true
                        onTriggered: backlight.apply()
                        // and once more on release, so the final value always lands
                        onRunningChanged: if (!running)
                            backlight.apply()
                    }
                    // re-read whenever the panel opens; the hardware keys change
                    // it behind our back
                    onVisibleChanged: if (visible)
                        readBrightness.running = true
                    Component.onCompleted: readBrightness.running = true

                    ColumnLayout {
                        id: light
                        x: 14
                        y: 12
                        width: parent.width - 28
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "brightness"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }
                            Text {
                                text: Math.round(backlight.pct * 100) + "%"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        Slider {
                            id: brightness
                            Layout.fillWidth: true
                            implicitHeight: 34
                            // never all the way to black
                            from: 0.01
                            to: 1
                            value: backlight.pct
                            onMoved: backlight.pct = value
                            background: Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Theme.pill
                                Rectangle {
                                    // never shorter than the icon it holds
                                    width: Math.max(parent.height, brightness.visualPosition * parent.width)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.yellow
                                }
                                Text {
                                    x: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰃞"
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                            handle: Item {}
                        }
                    }
                }
            }

            // ── Power ──
            RowLayout {
                Layout.fillWidth: true
                visible: panel.tab === 4
                spacing: 6

                Repeater {
                    model: [
                        {
                            icon: "󰌾",
                            label: "lock",
                            cmd: ["hyprlock"]
                        },
                        {
                            icon: "󰒲",
                            label: "suspend",
                            cmd: ["systemctl", "suspend"]
                        },
                        {
                            icon: "󰍃",
                            label: "log out",
                            cmd: ["hyprctl", "dispatch", "exit"]
                        },
                        {
                            icon: "󰜉",
                            label: "reboot",
                            cmd: ["systemctl", "reboot"]
                        },
                        {
                            icon: "󰐥",
                            label: "power off",
                            accent: true,
                            cmd: ["systemctl", "poweroff"]
                        }
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: 16
                        color: modelData.accent ? Theme.accent : Theme.bg

                        HoverHandler {
                            id: tileHover
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "#ffffff"
                            opacity: tileHover.hovered ? 0.10 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                color: modelData.accent ? Theme.bg : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 20
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: modelData.accent ? Theme.bg : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 4
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                panel.tab = -1;
                                Quickshell.execDetached(parent.modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
    }
}
