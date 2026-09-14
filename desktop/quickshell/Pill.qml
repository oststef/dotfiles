// One rounded pill per element
import QtQuick

Rectangle {
    property alias text: label.text
    property alias textColor: label.color
    property alias labelWidth: label.width
    // false for the pills that are only labels, so they don't fake a click target
    property bool hoverable: true
    property int padding: 14
    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: label.implicitHeight + 10
    radius: height / 2
    color: Theme.pill

    HoverHandler {
        id: hover
    }
    // tint over whatever colour the caller set, so it works on every variant
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "#ffffff"
        opacity: hover.hovered && parent.hoverable ? 0.10 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSize
            bold: true
        }
    }
}
