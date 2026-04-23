import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Cliphist-backed clipboard-history overlay. Styled with the same
// BarChrome / PixelFrame components as the launcher so the theme is
// consistent. On selection, decode the entry via `cliphist decode <id>`
// into the Wayland clipboard and invoke the user's paste.sh helper.
PanelWindow {
    id: root

    signal dismissed()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // --- clipboard entries ---------------------------------------------
    // Each entry: { id: "123", preview: "the copied text" }
    property var allEntries: []

    Process {
        id: clipLoader
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (text || "").split("\n").filter(function(s) { return s.length > 0 })
                root.allEntries = lines.map(function(line) {
                    var tab = line.indexOf("\t")
                    if (tab < 0) return { id: line, preview: line }
                    return { id: line.substring(0, tab), preview: line.substring(tab + 1) }
                })
            }
        }
    }

    readonly property string query: search.text
    readonly property var entries: {
        var q = query.trim().toLowerCase()
        if (q === "") return allEntries.slice(0, 200)
        return allEntries.filter(function(e) {
            return (e.preview || "").toLowerCase().indexOf(q) >= 0
        }).slice(0, 200)
    }

    function previewOf(entry) {
        var s = entry && entry.preview !== undefined ? entry.preview : ""
        return String(s || "").replace(/\n+/g, " ⏎ ")
    }

    function pickSelected() {
        var idx = listView.currentIndex
        if (idx < 0 || idx >= entries.length) return
        var entry = entries[idx]
        if (!entry || !entry.id) return
        var id = String(entry.id).replace(/[^0-9]/g, "")
        if (!id) return
        Quickshell.execDetached(["sh", "-c",
            "cliphist decode " + id + " | wl-copy && sleep 0.1 && exec \"$HOME/.config/hypr/scripts/paste.sh\""
        ])
        root.dismissed()
    }

    // --- visual backdrop & click-to-dismiss ----------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        antialiasing: false
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    // --- pocket --------------------------------------------------------
    Item {
        id: pocket
        width: 640
        height: 500
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 140

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        BarChrome { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.frameBorder + 4
            spacing: 6

            // --- search input ---
            PixelFrame {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                contentPadding: 10

                Row {
                    anchors.fill: parent
                    spacing: 8

                    // Clipboard glyph ✂ — clearly not the launcher.
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✂"
                        color: Theme.cyan
                        font.family: Theme.pixelFont
                        font.pixelSize: Theme.pixelSizeBody
                        renderType: Text.NativeRendering
                        antialiasing: false
                    }

                    TextInput {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        color: Theme.text
                        font.family: Theme.pixelFontBody
                        font.pixelSize: Theme.pixelSizeBody
                        selectionColor: Theme.magenta
                        selectedTextColor: Theme.textInverse
                        selectByMouse: true
                        clip: true
                        focus: true
                        renderType: Text.NativeRendering

                        cursorDelegate: Rectangle {
                            width: 2
                            color: Theme.cyan
                            visible: search.cursorVisible
                            antialiasing: false
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "filter clipboard…"
                            visible: search.text.length === 0
                            color: Theme.textDim
                            font: search.font
                            renderType: Text.NativeRendering
                            antialiasing: false
                        }

                        onTextChanged: listView.currentIndex = 0

                        Keys.onEscapePressed: root.dismissed()
                        Keys.onReturnPressed: root.pickSelected()
                        Keys.onEnterPressed: root.pickSelected()
                        Keys.onDownPressed: listView.incrementCurrentIndex()
                        Keys.onUpPressed: listView.decrementCurrentIndex()
                        Keys.onTabPressed: listView.incrementCurrentIndex()
                        Keys.onBacktabPressed: listView.decrementCurrentIndex()
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_PageDown) {
                                for (var i = 0; i < 8; ++i) listView.incrementCurrentIndex()
                                event.accepted = true
                            } else if (event.key === Qt.Key_PageUp) {
                                for (var j = 0; j < 8; ++j) listView.decrementCurrentIndex()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            // --- entries list ---
            PixelFrame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentPadding: 4

                ListView {
                    id: listView
                    anchors.fill: parent
                    clip: true
                    model: root.entries
                    currentIndex: 0
                    keyNavigationWraps: false
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: 32
                        radius: Theme.frameRadius
                        antialiasing: false
                        color: ListView.isCurrentItem ? Qt.rgba(0.13, 0.9, 0.9, 0.18) : "transparent"
                        border.color: ListView.isCurrentItem ? Theme.cyan : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            // Dim magenta index tag like "#07".
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "#" + (item.index + 1)
                                color: Theme.magentaDim
                                font.family: Theme.pixelFont
                                font.pixelSize: Theme.pixelSizeSmall
                                renderType: Text.NativeRendering
                                antialiasing: false
                                width: 28
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.previewOf(item.modelData)
                                color: item.ListView.isCurrentItem ? Theme.cyan : Theme.text
                                font.family: Theme.pixelFontBody
                                font.pixelSize: Theme.pixelSizeBody
                                renderType: Text.NativeRendering
                                antialiasing: false
                                elide: Text.ElideRight
                                width: parent.width - 46
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: listView.currentIndex = item.index
                            onClicked: root.pickSelected()
                        }
                    }

                    // Empty state.
                    Text {
                        anchors.centerIn: parent
                        visible: root.entries.length === 0
                        text: root.allEntries.length === 0 ? "no clipboard history" : "no matches"
                        color: Theme.textDim
                        font.family: Theme.pixelFont
                        font.pixelSize: Theme.pixelSize
                        renderType: Text.NativeRendering
                        antialiasing: false
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        clipLoader.running = true
        search.forceActiveFocus()
    }
}
