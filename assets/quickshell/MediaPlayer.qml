import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Media segment: music-note icon, "Title — Artist", transport buttons,
// tiny animated bar visualizer. Picks the first active player from MPRIS.
Item {
    id: root

    // Find a playing player first, else the first player at all.
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: {
        if (!players || players.length === 0) return null
        for (var i = 0; i < players.length; ++i) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        }
        return players[0]
    }
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing

    readonly property string title: hasPlayer && player.trackTitle ? player.trackTitle : "—"
    readonly property string artist: {
        if (!hasPlayer) return "no media"
        if (player.trackArtists && player.trackArtists.length > 0) return player.trackArtists.join(", ")
        if (player.trackArtist) return player.trackArtist
        return ""
    }
    readonly property string displayText: artist.length > 0 ? (title + " — " + artist) : title

    implicitHeight: row.implicitHeight
    implicitWidth:  row.implicitWidth

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 8

        // Pixel-art eighth-note glyph.
        Text {
            text: "♪"
            color: Theme.cyan
            font.family: Theme.pixelFont
            font.pixelSize: Theme.pixelSizeBody
            renderType: Text.NativeRendering
            antialiasing: false
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: label
            text: root.displayText
            color: Theme.cyan
            font.family: Theme.pixelFontBody
            font.pixelSize: Theme.pixelSizeBody
            renderType: Text.NativeRendering
            antialiasing: false
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 260
            Layout.maximumWidth: 260
        }

        TransportButton {
            glyph: "⏮"   // ⏮
            enabled: root.hasPlayer && root.player.canGoPrevious
            onActivated: if (root.hasPlayer) root.player.previous()
        }
        TransportButton {
            glyph: root.isPlaying ? "⏸" : "▶"  // ⏸ / ▶
            enabled: root.hasPlayer && root.player.canTogglePlaying
            onActivated: if (root.hasPlayer) root.player.togglePlaying()
        }
        TransportButton {
            glyph: "⏭"   // ⏭
            enabled: root.hasPlayer && root.player.canGoNext
            onActivated: if (root.hasPlayer) root.player.next()
        }

        // Tiny animated bar visualizer.
        Row {
            id: viz
            spacing: 1
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            readonly property bool animating: root.isPlaying

            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: 2
                    height: 4
                    color: Theme.cyan
                    antialiasing: false
                    y: viz.height - height
                    Behavior on height { NumberAnimation { duration: 160 } }
                }
            }

            Timer {
                interval: 140
                running: viz.animating && root.visible
                repeat: true
                onTriggered: {
                    for (var i = 0; i < viz.children.length; ++i) {
                        var c = viz.children[i]
                        if (c.hasOwnProperty("height")) c.height = 2 + Math.floor(Math.random() * 14)
                    }
                }
            }
        }
    }

    component TransportButton: Rectangle {
        id: btn
        signal activated()
        property string glyph: ""
        property bool enabled: true

        implicitWidth: 20
        implicitHeight: 20
        radius: Theme.frameRadius
        antialiasing: false
        color: mouse.containsMouse && btn.enabled ? Qt.rgba(1, 0.31, 0.81, 0.15) : "transparent"
        border.color: btn.enabled ? Theme.magentaDim : Qt.rgba(0.4, 0.24, 0.54, 0.4)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.enabled ? Theme.magenta : Theme.textDim
            font.family: Theme.pixelFont
            font.pixelSize: Theme.pixelSize
            renderType: Text.NativeRendering
            antialiasing: false
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: btn.enabled
            onClicked: btn.activated()
        }
    }
}
