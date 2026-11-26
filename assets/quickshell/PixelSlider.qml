import QtQuick

// Segmented volume slider: a row of blocky cells that light up to the
// current value, matching the 4-bar meter in the bar's volume pocket.
// Click or drag anywhere on the track to set it; scroll nudges by 2%.
Item {
    id: root

    property real  value: 0
    property real  maximum: 1.0
    property color fillColor: Theme.magenta
    property color dimColor:  Theme.magentaDim
    property bool  interactive: true

    // Emitted on click / drag / scroll. The parent writes it through to
    // Pipewire, which echoes back into `value`.
    signal moved(real value)

    implicitWidth:  160
    implicitHeight: 16

    readonly property int cellWidth: 4
    readonly property int cellGap:   2
    readonly property int cellCount: Math.max(1, Math.floor((width + cellGap) / (cellWidth + cellGap)))
    readonly property real fraction: maximum > 0 ? Math.max(0, Math.min(1, value / maximum)) : 0

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.cellGap

        Repeater {
            model: root.cellCount

            Rectangle {
                required property int index
                // Half-cell offset so a cell lights as the value crosses
                // its middle rather than its leading edge.
                readonly property bool lit: (index + 0.5) / root.cellCount <= root.fraction

                width: root.cellWidth
                height: root.height - 4
                color: lit ? root.fillColor : root.dimColor
                opacity: !root.interactive ? 0.2 : (lit ? 1.0 : 0.35)
                antialiasing: false
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        // Keep the drag once started even if the pointer wanders into the
        // enclosing ListView, which would otherwise steal it for flicking.
        preventStealing: true

        function applyAt(x) {
            var f = Math.max(0, Math.min(1, x / Math.max(1, root.width)))
            root.moved(f * root.maximum)
        }

        onPressed: function(mouse) { applyAt(mouse.x) }
        onPositionChanged: function(mouse) { if (pressed) applyAt(mouse.x) }
        onWheel: function(wheel) {
            var step = (wheel.angleDelta.y > 0 ? 0.02 : -0.02) * root.maximum
            root.moved(Math.max(0, Math.min(root.maximum, root.value + step)))
        }
    }
}
