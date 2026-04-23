import QtQuick
import Quickshell

// HH:mm clock driven by Quickshell's SystemClock so it ticks cheaply
// at minute precision instead of spinning a 1s Timer.
Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    implicitWidth:  label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "h:mm AP")
        color: Theme.cyan
        font.family: Theme.pixelFont
        font.pixelSize: Theme.pixelSizeClock
        renderType: Text.NativeRendering
        antialiasing: false
    }
}
