import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Full-screen overlay window. Dark backdrop + a centered launcher pocket
// styled with the same BarChrome used by the top bar. Search filters the
// DesktopEntries list; Up/Down navigates; Enter launches; Esc or click
// outside dismisses.
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

    // --- app list + filtering ------------------------------------------
    readonly property var allApps: {
        if (!DesktopEntries || !DesktopEntries.applications) return []
        return DesktopEntries.applications.values.filter(function(e) {
            return e && !e.noDisplay
        })
    }
    readonly property string query: search.text
    readonly property var apps: {
        var q = query.trim().toLowerCase()
        if (q === "") {
            return allApps.slice().sort(function(a, b) {
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            })
        }
        // Rank: name-prefix > name-substring > generic-name > comment.
        function score(e) {
            var n = (e.name || "").toLowerCase()
            if (n.startsWith(q)) return 0
            if (n.indexOf(q) !== -1) return 1
            if ((e.genericName || "").toLowerCase().indexOf(q) !== -1) return 2
            if ((e.comment || "").toLowerCase().indexOf(q) !== -1) return 3
            return 99
        }
        return allApps
            .map(function(e) { return { e: e, s: score(e) } })
            .filter(function(r) { return r.s < 99 })
            .sort(function(a, b) {
                if (a.s !== b.s) return a.s - b.s
                return a.e.name.toLowerCase().localeCompare(b.e.name.toLowerCase())
            })
            .map(function(r) { return r.e })
    }

    function launchSelected() {
        var idx = listView.currentIndex
        if (idx < 0 || idx >= apps.length) return
        var entry = apps[idx]
        if (entry && typeof entry.execute === "function") entry.execute()
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

    // --- launcher pocket -----------------------------------------------
    Item {
        id: pocket
        width: 560
        height: 460
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 140

        // Swallow clicks so they don't reach the backdrop.
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

                    // Prompt chevron.
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▶"
                        color: Theme.cyan
                        font.family: Theme.pixelFont
                        font.pixelSize: Theme.pixelSize
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

                        // Placeholder text while empty.
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "run a program…"
                            visible: search.text.length === 0
                            color: Theme.textDim
                            font: search.font
                            renderType: Text.NativeRendering
                            antialiasing: false
                        }

                        onTextChanged: listView.currentIndex = 0

                        Keys.onEscapePressed: root.dismissed()
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
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

            // --- results list ---
            PixelFrame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentPadding: 4

                ListView {
                    id: listView
                    anchors.fill: parent
                    clip: true
                    model: root.apps
                    currentIndex: 0
                    keyNavigationWraps: false
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: 36
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

                            Image {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter
                                source: item.modelData && item.modelData.icon
                                    ? Quickshell.iconPath(item.modelData.icon, "")
                                    : ""
                                sourceSize.width: 22
                                sourceSize.height: 22
                                smooth: false
                                mipmap: false
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData ? item.modelData.name : ""
                                color: item.ListView.isCurrentItem ? Theme.cyan : Theme.text
                                font.family: Theme.pixelFontBody
                                font.pixelSize: Theme.pixelSizeBody
                                renderType: Text.NativeRendering
                                antialiasing: false
                                elide: Text.ElideRight
                                width: parent.width - 32 - parent.spacing
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: listView.currentIndex = item.index
                            onClicked: root.launchSelected()
                        }
                    }

                    // Empty state.
                    Text {
                        anchors.centerIn: parent
                        visible: root.apps.length === 0
                        text: "no matches"
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

    Component.onCompleted: search.forceActiveFocus()
}
