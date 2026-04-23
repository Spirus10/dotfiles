import QtQuick

// Small cyan pixel-art "+" used as a decorative separator between
// segment pockets, so the bar material reads as a continuous chassis.
Item {
    id: root
    property color tint: Theme.barTopRim
    property real pixel: 1

    implicitWidth: pixel * 7
    implicitHeight: pixel * 7

    // Vertical stroke of the +
    Rectangle {
        x: root.pixel * 3
        y: 0
        width: root.pixel
        height: root.pixel * 7
        color: root.tint
        opacity: 0.85
        antialiasing: false
    }
    // Horizontal stroke of the +
    Rectangle {
        x: 0
        y: root.pixel * 3
        width: root.pixel * 7
        height: root.pixel
        color: root.tint
        opacity: 0.85
        antialiasing: false
    }
    // Brighter center pixel.
    Rectangle {
        x: root.pixel * 3
        y: root.pixel * 3
        width: root.pixel
        height: root.pixel
        color: "white"
        opacity: 0.9
        antialiasing: false
    }
}
