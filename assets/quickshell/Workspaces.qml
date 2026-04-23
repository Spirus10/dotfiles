import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// Five numbered workspace tiles. Active one is filled magenta; others
// show just a dim outline and number. Click dispatches to that workspace.
Item {
    id: root

    property int count: 5
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root.count

            Rectangle {
                id: tile
                required property int index
                readonly property int wsId: index + 1
                readonly property bool active: wsId === root.focusedId

                Layout.preferredWidth:  22
                Layout.preferredHeight: 22
                radius: Theme.frameRadius
                antialiasing: false

                color: active ? Theme.cyan : "transparent"
                border.color: active ? Theme.cyan : Theme.magentaDim
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: tile.wsId
                    color: tile.active ? Theme.textInverse : Theme.textDim
                    font.family: Theme.pixelFont
                    font.pixelSize: Theme.pixelSize
                    renderType: Text.NativeRendering
                    antialiasing: false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + tile.wsId)
                }
            }
        }
    }
}
