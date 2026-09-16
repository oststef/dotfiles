pragma Singleton

// System state shared by every window. Lives here, not in Bar.qml, because
// Bar is instantiated per monitor and these must exist exactly once.
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    // Audio: keep the default sink's volume data live
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: [root.sink]
    }

    // Audio devices for the panel's picker. Matching the type exactly keeps out
    // app streams and the .split helper nodes wireplumber makes per device.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)

    // Network: the wifi device's connected network, if any
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var wifiNetwork: root.wifiDevice?.networks?.values?.find(n => n.connected) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)

    // Power: displayDevice is whatever UPower considers the machine's battery,
    // absent on a desktop — every consumer guards on isLaptopBattery.
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: root.battery?.isLaptopBattery ?? false
    readonly property bool charging: root.battery?.state === UPowerDeviceState.Charging || root.battery?.state === UPowerDeviceState.FullyCharged

    // Media: first player that's actually playing
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    // Notifications: we are the notification daemon now, so swaync must not be
    // running — only one process can own org.freedesktop.Notifications.
    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        onNotification: n => {
            root.notifTimes[n.id] = new Date();
            n.tracked = true;
            // dismissing from the panel must also take down its toast
            n.closed.connect(() => {
                delete root.notifTimes[n.id];
                root.dropPopup(n);
            });
            root.popups = [n, ...root.popups].slice(0, 5);
        }
    }

    // Arrival times, by notification id: the server doesn't keep one.
    // ponytail: plain object, no change signal — the delegate reads it once at
    // creation, which is all a fixed clock time needs.
    property var notifTimes: ({})
    // empty for anything restored across a reload, whose arrival we never saw
    function notifTime(n) {
        const t = notifTimes[n.id];
        return t ? Qt.formatDateTime(t, "HH:mm") : "";
    }

    // Everything still in the tray, shown by the panel's notification tab
    readonly property var notifications: server.trackedNotifications
    readonly property int notifCount: server.trackedNotifications.values.length

    // Subset currently shown as a toast. Dropping a popup only hides the toast;
    // the notification stays in the list until it's dismissed.
    property var popups: []
    function dropPopup(n) {
        popups = popups.filter(p => p !== n);
    }
    function dismissAll() {
        // copy first: dismissing mutates the model we'd be iterating
        [...server.trackedNotifications.values].forEach(n => n.dismiss());
    }
}
