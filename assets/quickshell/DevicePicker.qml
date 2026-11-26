import QtQuick
import QtQuick.Layouts

// One device section of the mixer: a collapsible picker for the default
// device, plus that device's own slider, mute toggle and level meter.
// Drives both the output (sink) and input (source) halves.
PixelFrame {
    id: root

    property string label: "OUT"
    property var    devices: []
    property var    current: null
    property bool   expanded: false
    // Swaps the speaker glyphs for a microphone.
    property bool   input: false

    signal deviceSelected(var device)
    signal muteToggled()
    signal volumeRequested(real volume)

    readonly property real volume: current && current.audio ? current.audio.volume : 0
    readonly property bool muted:  current && current.audio ? current.audio.muted  : false

    function deviceLabel(node) {
        if (!node) return root.input ? "no input device" : "no output device"
        return node.description || node.nickname || node.name || "unknown device"
    }

    Layout.fillWidth: true
    Layout.preferredHeight: column.implicitHeight + (Theme.frameBorder + 2) * 2
    contentPadding: 8

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 6

        // Picker header — click anywhere on it to expand the list. Wrapped
        // in a plain Item so the MouseArea isn't a layout-managed child.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: root.label
                    color: Theme.cyan
                    font.family: Theme.pixelFont
                    font.pixelSize: Theme.pixelSizeSmall
                    renderType: Text.NativeRendering
                    antialiasing: false
                }

                Text {
                    Layout.fillWidth: true
                    text: root.deviceLabel(root.current)
                    color: Theme.text
                    font.family: Theme.pixelFontBody
                    font.pixelSize: Theme.pixelSizeBody
                    renderType: Text.NativeRendering
                    antialiasing: false
                    elide: Text.ElideRight
                }

                Text {
                    text: root.expanded ? "▲" : "▼"
                    color: Theme.magenta
                    font.family: Theme.pixelFontBody
                    font.pixelSize: Theme.pixelSizeBody
                    renderType: Text.NativeRendering
                    antialiasing: false
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }

        // Expanded device list.
        Repeater {
            model: root.expanded ? root.devices : []

            Rectangle {
                id: deviceRow
                required property var modelData

                readonly property bool isCurrent: modelData === root.current

                Layout.fillWidth: true
                Layout.preferredHeight: 22
                radius: Theme.frameRadius
                antialiasing: false
                color: deviceArea.containsMouse ? Qt.rgba(0.13, 0.9, 0.9, 0.12) : "transparent"
                border.color: deviceRow.isCurrent ? Theme.cyan : "transparent"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: deviceRow.isCurrent ? "●" : "○"
                        color: deviceRow.isCurrent ? Theme.cyan : Theme.textDim
                        font.family: Theme.pixelFontBody
                        font.pixelSize: Theme.pixelSizeBody
                        renderType: Text.NativeRendering
                        antialiasing: false
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        text: root.deviceLabel(deviceRow.modelData)
                        color: deviceRow.isCurrent ? Theme.cyan : Theme.text
                        font.family: Theme.pixelFontBody
                        font.pixelSize: Theme.pixelSizeBody
                        renderType: Text.NativeRendering
                        antialiasing: false
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: deviceArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.deviceSelected(deviceRow.modelData)
                        root.expanded = false
                    }
                }
            }
        }

        // Volume for the selected device.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 8

            Text {
                text: root.muted
                    ? "🔇"
                    : (root.input ? "🎤"
                                  : (root.volume < 0.01 ? "🔈" : (root.volume < 0.5 ? "🔉" : "🔊")))
                color: root.muted ? Theme.magentaDim : Theme.cyan
                font.family: Theme.pixelFont
                font.pixelSize: Theme.pixelSizeBody
                renderType: Text.NativeRendering
                antialiasing: false

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteToggled()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                PixelSlider {
                    Layout.fillWidth: true
                    value: root.volume
                    fillColor: root.muted ? Theme.magentaDim : Theme.magenta
                    onMoved: function(v) { root.volumeRequested(v) }
                }

                PeakMeter {
                    Layout.fillWidth: true
                    nodes: root.current ? [root.current] : []
                    active: !root.muted
                }
            }

            Text {
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
                text: root.muted ? "MUTE" : Math.round(root.volume * 100) + "%"
                color: root.muted ? Theme.magentaDim : Theme.text
                font.family: Theme.pixelFont
                font.pixelSize: Theme.pixelSizeSmall
                renderType: Text.NativeRendering
                antialiasing: false
            }
        }
    }
}
