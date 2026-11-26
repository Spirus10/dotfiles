import QtQuick
import Quickshell.Services.Pipewire

// Thin live level bar, like the green meter beside each app in the
// Windows mixer. Takes a list of nodes so a grouped application shows one
// meter across all of its streams — the bars overlay, so the loudest one
// is what you see. The peak monitors tap the nodes directly, so they only
// run while the mixer window exists.
Item {
    id: root

    property var  nodes: []
    property bool active: true

    implicitHeight: 3
    implicitWidth: 100

    Rectangle {
        anchors.fill: parent
        color: Theme.cyanDim
        opacity: 0.25
        antialiasing: false
    }

    Repeater {
        model: root.nodes

        Item {
            id: channel
            required property var modelData

            anchors.fill: parent

            PwNodePeakMonitor {
                id: monitor
                node: channel.modelData
                enabled: root.active && root.visible
            }

            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, root.active ? monitor.peak : 0))
                color: Theme.teal
                antialiasing: false

                // Short ramp so the bar reads as a level meter rather than
                // flickering once per pipewire tick.
                Behavior on width {
                    NumberAnimation { duration: 70 }
                }
            }
        }
    }
}
