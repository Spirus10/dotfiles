import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Windows-style volume mixer flyout, hanging under the bar's volume
// pocket. Output and input device pickers on top, each with the selected
// device's own slider; below them, one row per playing *program* — a
// browser's tabs collapse into a single slider — with mute, a live level
// meter and per-program output routing.
//
// Opened by right-clicking the bar's VolumeIndicator. The full-screen
// backdrop dismisses it, so a second right-click closes it again.
PanelWindow {
    id: root

    signal dismissed()

    // Distance from the right screen edge to the right edge of the bar's
    // volume pocket, so the flyout lines up underneath it.
    property real anchorRightMargin: 12

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


    // --- pipewire node lists --------------------------------------------
    // Quickshell's flags read from the graph's point of view: an app that
    // is playing audio is a Sink (audio flows *into* it from the app) that
    // is also a Stream, while a real output device is a Sink that is not.
    // Capture devices are neither.
    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

    readonly property var sinks: nodes.filter(function(n) {
        return n && n.audio && n.isSink && !n.isStream
    }).sort(function(a, b) {
        return root.sinkLabel(a).toLowerCase().localeCompare(root.sinkLabel(b).toLowerCase())
    })

    readonly property var sources: nodes.filter(function(n) {
        return n && n.audio && !n.isSink && !n.isStream
    }).sort(function(a, b) {
        return root.sinkLabel(a).toLowerCase().localeCompare(root.sinkLabel(b).toLowerCase())
    })

    // Sorted by id so rows keep their place as the graph churns.
    readonly property var streams: nodes.filter(function(n) {
        return n && n.audio && n.isSink && n.isStream
    }).sort(function(a, b) { return a.id - b.id })

    // One row per *program*, not per stream: a browser with three noisy
    // tabs gets a single slider. Streams from one process share a pid, so
    // that's the grouping key wherever pipewire reports it.
    readonly property var streamGroups: {
        var groups = []
        var byKey = ({})
        for (var i = 0; i < streams.length; ++i) {
            var node = streams[i]
            var key = root.groupKey(node)
            if (!byKey[key]) {
                byKey[key] = { key: key, lead: node, nodes: [] }
                groups.push(byKey[key])
            }
            byKey[key].nodes.push(node)
        }
        return groups
    }

    function groupKey(node) {
        var p = (node && node.properties) || {}
        return p["application.process.id"] || p["application.name"] || ("node-" + node.id)
    }

    // Only here so name/icon bindings re-run once the entries finish
    // loading — heuristicLookup() is a plain call and wouldn't retrigger.
    readonly property int desktopEntryCount:
        DesktopEntries && DesktopEntries.applications ? DesktopEntries.applications.values.length : 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Where each stream currently lands. PwNodeLinkTracker comes up empty
    // for pre-existing links, so read the global link groups instead: for
    // a playback stream the group's source is the stream and its target
    // is the sink it is feeding.
    readonly property var linkGroups: Pipewire.linkGroups ? Pipewire.linkGroups.values : []

    function sinkForStream(node) {
        if (!node) return null
        for (var i = 0; i < root.linkGroups.length; ++i) {
            var group = root.linkGroups[i]
            if (group && group.source === node && group.target) return group.target
        }
        return null
    }

    // Nothing on screen updates unless it is tracked. The window only
    // exists while the mixer is open, so the trackers — and the peak
    // monitors in the delegates — are torn down when it closes.
    PwObjectTracker {
        objects: root.sinks.concat(root.sources).concat(root.streams)
    }
    PwObjectTracker {
        objects: root.linkGroups
    }

    // --- labels & icons --------------------------------------------------
    function sinkLabel(node) {
        if (!node) return "no output device"
        return node.description || node.nickname || node.name || "unknown device"
    }

    function sinkShortLabel(node) {
        if (!node) return "no output device"
        return node.nickname || node.description || node.name || "unknown device"
    }

    function streamApp(node) {
        if (!node) return "unknown"
        var p = node.properties || {}
        return p["application.name"] || node.description || node.name || "unknown"
    }

    // Desktop entry behind a stream, if one can be guessed. Gives a nicer
    // program name than the stream's own — Discord's playback stream calls
    // itself "WEBRTC VoiceEngine".
    function entryFor(node) {
        if (root.desktopEntryCount === 0) return null
        var p = (node && node.properties) || {}
        var candidates = [
            p["application.id"] || "",
            p["application.process.binary"] || "",
            p["application.name"] || ""
        ]
        for (var i = 0; i < candidates.length; ++i) {
            // Nix wraps binaries as ".<name>-wrapped"; strip that before
            // asking for a desktop entry (".Discord-wrapped" → "Discord").
            var name = candidates[i]
                .replace(/^\./, "")
                .replace(/-wrapped$/, "")
                .replace(/\.desktop$/, "")
            if (!name) continue
            var entry = DesktopEntries.heuristicLookup(name)
            if (entry) return entry
        }
        return null
    }

    function groupName(group) {
        if (!group) return "unknown"
        var entry = root.entryFor(group.lead)
        if (entry && entry.name) return entry.name
        return root.streamApp(group.lead)
    }

    // Second line of an app row: the track/stream title for a single
    // stream, or a count once a program has several going at once.
    function groupTitle(group) {
        if (!group) return ""
        if (group.nodes.length > 1) return group.nodes.length + " streams"
        var p = (group.lead && group.lead.properties) || {}
        var media = p["media.name"] || ""
        return media === root.groupName(group) ? "" : media
    }

    function groupIcon(group) {
        if (!group) return ""
        var p = (group.lead && group.lead.properties) || {}
        var direct = p["application.icon_name"] || p["window.icon_name"] || ""
        if (direct) return Quickshell.iconPath(direct, "")

        var entry = root.entryFor(group.lead)
        return entry && entry.icon ? Quickshell.iconPath(entry.icon, "") : ""
    }

    // A program's slider shows its loudest stream and drives all of them;
    // it counts as muted only once every stream is.
    function groupVolume(group) {
        var max = 0
        if (!group) return max
        for (var i = 0; i < group.nodes.length; ++i) {
            var audio = group.nodes[i].audio
            if (audio && audio.volume > max) max = audio.volume
        }
        return max
    }

    function groupMuted(group) {
        if (!group || group.nodes.length === 0) return false
        for (var i = 0; i < group.nodes.length; ++i) {
            var audio = group.nodes[i].audio
            if (audio && !audio.muted) return false
        }
        return true
    }

    function glyphFor(volume, muted) {
        if (muted) return "🔇"
        if (volume < 0.01) return "🔈"
        return volume < 0.5 ? "🔉" : "🔊"
    }

    // --- mutations -------------------------------------------------------
    function setVolume(node, v) {
        if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute(node) {
        if (node && node.audio) node.audio.muted = !node.audio.muted
    }

    function setGroupVolume(group, v) {
        if (!group) return
        for (var i = 0; i < group.nodes.length; ++i) root.setVolume(group.nodes[i], v)
    }

    function toggleGroupMute(group) {
        if (!group) return
        var muted = !root.groupMuted(group)
        for (var i = 0; i < group.nodes.length; ++i) {
            if (group.nodes[i].audio) group.nodes[i].audio.muted = muted
        }
    }

    function selectSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function selectSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }

    // Per-app routing. Quickshell can't move a stream, but wireplumber
    // honours a `target.object` entry in the default metadata store;
    // deleting it puts the stream back on whatever the default sink is.
    function routeGroup(group, target) {
        if (!group) return
        for (var i = 0; i < group.nodes.length; ++i) {
            var id = String(group.nodes[i].id)
            if (target) {
                Quickshell.execDetached(["pw-metadata", id,
                                         "target.object", "\"" + target.name + "\""])
            } else {
                Quickshell.execDetached(["pw-metadata", "-d", id, "target.object"])
            }
        }
    }

    // --- dismissal -------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        antialiasing: false
    }
    MouseArea {
        anchors.fill: parent
        // Right button too: the second right-click on the volume pocket
        // lands here when the backdrop covers the bar.
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.dismissed()
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.dismissed()
    }

    // --- flyout ----------------------------------------------------------
    Item {
        id: pocket

        readonly property int pad: Theme.frameBorder + 4

        width: 470
        height: Math.min(layout.implicitHeight + pad * 2, root.height - 24)
        anchors.top: parent.top
        anchors.topMargin: Theme.barPadding
        anchors.right: parent.right
        anchors.rightMargin: root.anchorRightMargin

        // Swallow clicks so they don't reach the dismiss backdrop.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {}
        }

        BarChrome { anchors.fill: parent }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: pocket.pad
            spacing: 6

            // --- title -----------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 8

                Text {
                    text: "VOLUME MIXER"
                    color: Theme.teal
                    font.family: Theme.pixelFont
                    font.pixelSize: Theme.pixelSize
                    renderType: Text.NativeRendering
                    antialiasing: false
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "ESC"
                    color: Theme.textDim
                    font.family: Theme.pixelFont
                    font.pixelSize: Theme.pixelSizeSmall
                    renderType: Text.NativeRendering
                    antialiasing: false
                }

                Text {
                    text: "✕"
                    color: closeArea.containsMouse ? Theme.magentaGlow : Theme.magenta
                    font.family: Theme.pixelFontBody
                    font.pixelSize: Theme.pixelSizeBody
                    renderType: Text.NativeRendering
                    antialiasing: false

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            // --- output device + volume --------------------------------
            // Only one list is open at a time, so the flyout can't grow
            // taller than the screen on a machine with many devices.
            DevicePicker {
                id: outputPicker
                label: "OUT"
                devices: root.sinks
                current: root.sink
                onExpandedChanged: if (expanded) inputPicker.expanded = false
                onDeviceSelected: function(device) { root.selectSink(device) }
                onMuteToggled: root.toggleMute(root.sink)
                onVolumeRequested: function(v) { root.setVolume(root.sink, v) }
            }

            // --- input device + volume ---------------------------------
            DevicePicker {
                id: inputPicker
                label: "IN"
                input: true
                devices: root.sources
                current: root.source
                onExpandedChanged: if (expanded) outputPicker.expanded = false
                onDeviceSelected: function(device) { root.selectSource(device) }
                onMuteToggled: root.toggleMute(root.source)
                onVolumeRequested: function(v) { root.setVolume(root.source, v) }
            }

            // --- apps header --------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.topMargin: 2
                spacing: 8

                Text {
                    text: "APPS"
                    color: Theme.teal
                    font.family: Theme.pixelFont
                    font.pixelSize: Theme.pixelSizeSmall
                    renderType: Text.NativeRendering
                    antialiasing: false
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.streamGroups.length + ""
                    color: Theme.textDim
                    font.family: Theme.pixelFont
                    font.pixelSize: Theme.pixelSizeSmall
                    renderType: Text.NativeRendering
                    antialiasing: false
                }
            }

            // --- per-app rows -------------------------------------------
            PixelFrame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 56
                Layout.preferredHeight: Math.max(56, Math.min(appList.contentHeight, 320))
                    + (Theme.frameBorder + 2) * 2
                contentPadding: 4

                ListView {
                    id: appList
                    anchors.fill: parent
                    clip: true
                    spacing: 2
                    model: root.streamGroups
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: appRow
                        required property var modelData

                        readonly property var group: modelData
                        readonly property bool muted: root.groupMuted(group)
                        readonly property real volume: root.groupVolume(group)
                        property bool routeOpen: false

                        width: ListView.view.width
                        height: mainRow.height + (routeOpen ? routeCol.height + 4 : 0)

                        // Where the program's first stream lands; a program
                        // whose streams straddle devices reads off that one.
                        readonly property var currentSink: root.sinkForStream(group.lead)

                        RowLayout {
                            id: mainRow
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            height: 54
                            spacing: 8

                            Image {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter
                                source: root.groupIcon(appRow.group)
                                sourceSize.width: 24
                                sourceSize.height: 24
                                smooth: false
                                mipmap: false
                                fillMode: Image.PreserveAspectFit

                                // Fallback glyph when no desktop entry matched.
                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.status !== Image.Ready
                                    text: "♪"
                                    color: Theme.cyanDim
                                    font.family: Theme.pixelFontBody
                                    font.pixelSize: Theme.pixelSizeBody
                                    renderType: Text.NativeRendering
                                    antialiasing: false
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: root.groupName(appRow.group)
                                        color: appRow.muted ? Theme.textDim : Theme.text
                                        font.family: Theme.pixelFontBody
                                        font.pixelSize: Theme.pixelSizeBody
                                        renderType: Text.NativeRendering
                                        antialiasing: false
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.groupTitle(appRow.group)
                                        color: Theme.textDim
                                        font.family: Theme.pixelFontBody
                                        font.pixelSize: Theme.pixelSizeSmall
                                        renderType: Text.NativeRendering
                                        antialiasing: false
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: appRow.muted ? "MUTE" : Math.round(appRow.volume * 100) + "%"
                                        color: appRow.muted ? Theme.magentaDim : Theme.textDim
                                        font.family: Theme.pixelFont
                                        font.pixelSize: Theme.pixelSizeSmall
                                        renderType: Text.NativeRendering
                                        antialiasing: false
                                    }
                                }

                                PixelSlider {
                                    Layout.fillWidth: true
                                    implicitHeight: 14
                                    value: appRow.volume
                                    fillColor: appRow.muted ? Theme.magentaDim : Theme.magenta
                                    onMoved: function(v) { root.setGroupVolume(appRow.group, v) }
                                }

                                PeakMeter {
                                    Layout.fillWidth: true
                                    nodes: appRow.group.nodes
                                    active: !appRow.muted
                                }
                            }

                            // Mute toggle.
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: root.glyphFor(appRow.volume, appRow.muted)
                                color: appRow.muted ? Theme.magentaDim : Theme.cyan
                                font.family: Theme.pixelFont
                                font.pixelSize: Theme.pixelSizeBody
                                renderType: Text.NativeRendering
                                antialiasing: false

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleGroupMute(appRow.group)
                                }
                            }

                            // Output routing toggle.
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: "⇄"
                                color: appRow.routeOpen ? Theme.magentaGlow : Theme.magentaDim
                                font.family: Theme.pixelFontBody
                                font.pixelSize: Theme.pixelSizeBody
                                renderType: Text.NativeRendering
                                antialiasing: false

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: appRow.routeOpen = !appRow.routeOpen
                                }
                            }
                        }

                        // Per-app output picker, revealed by ⇄.
                        Column {
                            id: routeCol
                            visible: appRow.routeOpen
                            anchors.top: mainRow.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 36
                            anchors.rightMargin: 8
                            spacing: 1

                            Repeater {
                                model: appRow.routeOpen
                                    ? [null].concat(root.sinks)  // null = follow the default sink
                                    : []

                                Rectangle {
                                    id: routeRow
                                    required property var modelData

                                    readonly property bool current:
                                        modelData ? modelData === appRow.currentSink : false

                                    width: routeCol.width
                                    height: 20
                                    radius: Theme.frameRadius
                                    antialiasing: false
                                    color: routeArea.containsMouse ? Qt.rgba(1.0, 0.31, 0.79, 0.12) : "transparent"
                                    border.color: routeRow.current ? Theme.magenta : "transparent"
                                    border.width: 1

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: routeRow.modelData
                                            ? (routeRow.current ? "▸ " : "  ") + root.sinkShortLabel(routeRow.modelData)
                                            : "  follow default"
                                        color: routeRow.current ? Theme.magenta : Theme.textDim
                                        font.family: Theme.pixelFontBody
                                        font.pixelSize: Theme.pixelSizeBody
                                        renderType: Text.NativeRendering
                                        antialiasing: false
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: routeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.routeGroup(appRow.group, routeRow.modelData)
                                            appRow.routeOpen = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty state.
                    Text {
                        anchors.centerIn: parent
                        visible: root.streams.length === 0
                        text: "nothing playing"
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
}
