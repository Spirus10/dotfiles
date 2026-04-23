import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Pipewire default-sink volume readout: speaker icon + percent + 4-bar
// signal meter drawn as blocky rectangles.
Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int percent: Math.round(volume * 100)

    // Needed so sink properties actually track changes.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        // Speaker glyph. Unicode 🔇 / 🔈 / 🔉 / 🔊 — scales well in most fonts.
        Text {
            text: root.muted ? "🔇" : (root.volume < 0.01 ? "🔈" : (root.volume < 0.5 ? "🔉" : "🔊"))
            color: Theme.cyan
            font.family: Theme.pixelFont
            font.pixelSize: Theme.pixelSizeBody
            renderType: Text.NativeRendering
            antialiasing: false
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.muted ? "MUTE" : root.percent + "%"
            color: Theme.text
            font.family: Theme.pixelFont
            font.pixelSize: Theme.pixelSize
            renderType: Text.NativeRendering
            antialiasing: false
            Layout.alignment: Qt.AlignVCenter
        }

        // 4-bar signal meter — lights up bars proportional to volume.
        Row {
            spacing: 1
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 3
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    // Each bar turns on as volume crosses 25/50/75/100%.
                    readonly property bool lit: !root.muted && root.volume * 4 >= (index + 1) * 0.95
                    width: 3
                    height: 4 + index * 3
                    color: lit ? Theme.magenta : Theme.magentaDim
                    opacity: lit ? 1.0 : 0.45
                    antialiasing: false
                }
            }
        }
    }

    // Scroll to adjust volume, click to mute.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.sink && root.sink.audio) root.sink.audio.muted = !root.muted
        }
        onWheel: function(wheel) {
            if (!root.sink || !root.sink.audio) return
            var step = wheel.angleDelta.y > 0 ? 0.02 : -0.02
            root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + step))
        }
    }
}
