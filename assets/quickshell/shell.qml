import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root

    signal mediaToggleRequested()
    property bool launcherVisible: false
    property bool clipboardVisible: false
    property var clipEntries: []

    IpcHandler {
        target: "media"
        function toggle(): void { root.mediaToggleRequested() }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.launcherVisible = !root.launcherVisible }
        function show(): void { root.launcherVisible = true }
        function hide(): void { root.launcherVisible = false }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.clipboardVisible = !root.clipboardVisible }
        function show(): void { root.clipboardVisible = true }
        function hide(): void { root.clipboardVisible = false }
    }

    Process {
        id: clipLoader
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (text || "").split("\n").filter(s => s.length > 0);
                root.clipEntries = lines.map(line => {
                    const tab = line.indexOf("\t");
                    if (tab < 0) return { id: line, preview: line };
                    return { id: line.substring(0, tab), preview: line.substring(tab + 1) };
                });
            }
        }
    }

    function reloadClipboard() {
        clipLoader.running = false;
        clipLoader.running = true;
    }

    function pickClip(entry) {
        if (!entry || !entry.id) return;
        const id = String(entry.id).replace(/[^0-9]/g, "");
        if (!id) return;
        Quickshell.execDetached(["sh", "-c",
            "cliphist decode " + id + " | wl-copy && sleep 0.1 && exec \"$HOME/.config/hypr/scripts/paste.sh\""
        ]);
        root.clipboardVisible = false;
    }

    function clipPreview(entry) {
        const s = entry && entry.preview !== undefined ? entry.preview : entry;
        return (s || "").replace(/\n+/g, " ⏎ ");
    }

    function fuzzyScore(query, target) {
        if (!target) return -1;
        query = query.toLowerCase();
        target = target.toLowerCase();
        if (query === "") return 1;
        const idx = target.indexOf(query);
        if (idx >= 0) return 1000 - idx;
        let qi = 0, ti = 0, score = 0, consec = 0;
        while (qi < query.length && ti < target.length) {
            if (query[qi] === target[ti]) {
                qi++;
                score += 1 + consec * 2;
                consec++;
            } else {
                consec = 0;
            }
            ti++;
        }
        return qi === query.length ? score : -1;
    }

    function filterApps(query) {
        const list = DesktopEntries.applications.values;
        if (!query) {
            return list.slice().sort((a, b) => (a.name || "").localeCompare(b.name || "")).slice(0, 60);
        }
        const scored = [];
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            const s = Math.max(
                root.fuzzyScore(query, e.name),
                root.fuzzyScore(query, e.genericName || "") - 50
            );
            if (s > 0) scored.push({ e: e, s: s });
        }
        scored.sort((a, b) => b.s - a.s);
        return scored.slice(0, 60).map(x => x.e);
    }

    function fmtTime(seconds) {
        if (!seconds || seconds < 0 || isNaN(seconds)) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    property QtObject palette: QtObject {
        property color base:      "#1b1c2b"
        property color baseAlt:   "#232438"
        property color surface:   "#2a2b42"
        property color fg:        "#eeffff"
        property color muted:     "#8b8fb0"
        property color lavender:  "#b4a4f4"
        property color violet:    "#b994f1"
        property color pink:      "#ff5370"
        property color magenta:   "#ff4cc7"
        property color cyan:      "#04d1f9"
        property color teal:      "#2df4c0"
    }

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            property int viewYear: clockTick.now.getFullYear()
            property int viewMonth: clockTick.now.getMonth()

            property bool mediaExpanded: false
            readonly property bool isFocusedPanel:
                Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === panel.modelData.name

            Connections {
                target: root
                function onMediaToggleRequested() {
                    if (panel.isFocusedPanel && panel.activePlayer) {
                        panel.mediaExpanded = !panel.mediaExpanded;
                    }
                }
            }

            onActivePlayerChanged: if (!activePlayer) mediaExpanded = false

            property var activePlayer: {
                const list = Mpris.players.values;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].playbackState === MprisPlaybackState.Playing) return list[i];
                }
                return list.length > 0 ? list[0] : null;
            }

            function resetView() {
                viewYear = clockTick.now.getFullYear();
                viewMonth = clockTick.now.getMonth();
            }
            function shiftMonth(delta) {
                let m = viewMonth + delta;
                let y = viewYear;
                while (m < 0)  { m += 12; y -= 1; }
                while (m > 11) { m -= 12; y += 1; }
                viewMonth = m;
                viewYear = y;
            }

            readonly property int collapsedH: 42
            readonly property int expandedH: 200

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: panel.mediaExpanded ? panel.expandedH : panel.collapsedH
            exclusiveZone: panel.collapsedH
            color: "transparent"

            Behavior on implicitHeight {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: bar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: panel.collapsedH - 16
                color: root.palette.base
                radius: 8
                border.color: root.palette.lavender
                border.width: 1

                Item {
                    id: topRow
                    anchors.fill: parent

                Row {
                    id: workspaces
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Item {
                            required property var modelData
                            readonly property bool isFocused: Hyprland.focusedWorkspace === modelData
                            readonly property bool isActive: modelData.active
                            width: wsLabel.implicitWidth + 8
                            height: 20

                            Behavior on width {
                                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
                            }

                            Text {
                                id: wsLabel
                                anchors.centerIn: parent
                                text: (isFocused || isActive)
                                    ? "[ " + modelData.name + " ]"
                                    : "[" + modelData.name + "]"
                                color: modelData.urgent
                                    ? root.palette.pink
                                    : (isFocused
                                        ? root.palette.cyan
                                        : (isActive
                                            ? root.palette.violet
                                            : root.palette.muted))
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                font.bold: isFocused || isActive

                                Behavior on color {
                                    ColorAnimation { duration: 140 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + modelData.id)
                            }
                        }
                    }
                }

                Item {
                    id: mediaWrap
                    anchors.centerIn: parent
                    visible: panel.activePlayer !== null
                    width: Math.min(mediaRow.implicitWidth, 420)
                    height: 26

                    property var player: panel.activePlayer
                    readonly property string titleText: player ? (player.trackTitle || "") : ""
                    readonly property string artistText: {
                        if (!player) return "";
                        const a = player.trackArtists;
                        if (Array.isArray(a)) return a.join(", ");
                        if (typeof a === "string") return a;
                        if (typeof player.trackArtist === "string") return player.trackArtist;
                        return "";
                    }
                    readonly property string displayText:
                        artistText ? titleText + "  —  " + artistText : titleText
                    readonly property bool isPlaying:
                        player && player.playbackState === MprisPlaybackState.Playing

                    property int _tick: 0
                    Timer {
                        interval: 1000
                        running: mediaWrap.isPlaying
                        repeat: true
                        onTriggered: mediaWrap._tick++
                    }

                    readonly property real progressFrac: {
                        _tick;
                        if (!player) return 0;
                        const len = player.length || 0;
                        if (len <= 0) return 0;
                        return Math.min(1, Math.max(0, (player.position || 0) / len));
                    }

                    Row {
                        id: mediaRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mediaWrap.isPlaying ? "\uF001" : "\uF04C"
                            color: root.palette.violet
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            width: Math.min(titleLabel.implicitWidth, 380)

                            Text {
                                id: titleLabel
                                width: parent.width
                                text: mediaWrap.displayText
                                color: root.palette.fg
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize - 1
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: parent.width
                                height: 2
                                color: root.palette.surface
                                radius: 1

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * mediaWrap.progressFrac
                                    color: root.palette.lavender
                                    radius: 1
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (mediaWrap.player) panel.mediaExpanded = !panel.mediaExpanded
                    }
                }

                Item {
                    id: clockWrap
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: clock.implicitWidth
                    height: clock.implicitHeight

                    Text {
                        id: clock
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clockTick.now, "ddd MMM d   hh:mm")
                        color: calendarPopup.visible ? root.palette.cyan : root.palette.fg
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }
                    }

                    QtObject {
                        id: clockTick
                        property date now: new Date()
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockTick.now = new Date()
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!calendarPopup.visible) panel.resetView();
                            calendarPopup.visible = !calendarPopup.visible;
                        }
                    }
                }
                }
            }

            Rectangle {
                id: expansion
                anchors.top: bar.bottom
                anchors.topMargin: -1
                anchors.horizontalCenter: parent.horizontalCenter
                width: 460
                height: panel.expandedH - panel.collapsedH - 4
                color: root.palette.base
                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: 8
                bottomRightRadius: 8
                border.color: root.palette.lavender
                border.width: 1
                clip: true

                opacity: panel.mediaExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Item {
                    id: expandedSection
                    anchors.fill: parent
                    anchors.margins: 14

                    Row {
                        anchors.fill: parent
                        spacing: 14

                        Rectangle {
                            width: 110
                            height: 110
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.palette.surface
                            radius: 6
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: panel.activePlayer ? (panel.activePlayer.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !panel.activePlayer || !panel.activePlayer.trackArtUrl
                                text: ""
                                color: root.palette.muted
                                font.family: root.fontFamily
                                font.pixelSize: 36
                            }
                        }

                        Column {
                            width: parent.width - 124
                            height: parent.height
                            spacing: 4

                            Text {
                                width: parent.width
                                text: panel.activePlayer ? (panel.activePlayer.trackTitle || "") : ""
                                color: root.palette.fg
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize + 1
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: mediaWrap.artistText
                                color: root.palette.muted
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                elide: Text.ElideRight
                            }

                            Item { width: 1; height: 6 }

                            Row {
                                spacing: 22
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    id: prevCtl
                                    text: ""
                                    color: root.palette.muted
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize + 4
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (panel.activePlayer) panel.activePlayer.previous()
                                        onEntered: prevCtl.color = root.palette.cyan
                                        onExited: prevCtl.color = root.palette.muted
                                    }
                                }

                                Text {
                                    id: playCtl
                                    text: mediaWrap.isPlaying ? "" : ""
                                    color: root.palette.violet
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize + 8
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (panel.activePlayer) panel.activePlayer.togglePlaying()
                                        onEntered: playCtl.color = root.palette.cyan
                                        onExited: playCtl.color = root.palette.violet
                                    }
                                }

                                Text {
                                    id: nextCtl
                                    text: ""
                                    color: root.palette.muted
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize + 4
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (panel.activePlayer) panel.activePlayer.next()
                                        onEntered: nextCtl.color = root.palette.cyan
                                        onExited: nextCtl.color = root.palette.muted
                                    }
                                }
                            }

                            Item { width: 1; height: 4 }

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: root.fmtTime(panel.activePlayer ? panel.activePlayer.position : 0)
                                    color: root.palette.muted
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize - 2
                                    width: 36
                                }

                                Rectangle {
                                    id: scrub
                                    width: parent.width - 80
                                    height: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.palette.surface
                                    radius: 2

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width * mediaWrap.progressFrac
                                        color: root.palette.lavender
                                        radius: 2
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            const p = panel.activePlayer;
                                            if (!p || !p.length || p.length <= 0) return;
                                            const frac = Math.min(1, Math.max(0, mouse.x / width));
                                            p.position = frac * p.length;
                                        }
                                    }
                                }

                                Text {
                                    text: root.fmtTime(panel.activePlayer ? panel.activePlayer.length : 0)
                                    color: root.palette.muted
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize - 2
                                    width: 36
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: seamPatch
                anchors.horizontalCenter: expansion.horizontalCenter
                anchors.top: expansion.top
                width: expansion.width - 2
                height: 2
                color: root.palette.base
                opacity: expansion.opacity
                visible: expansion.visible
                z: 10
            }

            PopupWindow {
                id: calendarPopup
                anchor {
                    window: panel
                    rect.x: panel.width - width - 8
                    rect.y: panel.implicitHeight - 4
                }
                implicitWidth: 240
                implicitHeight: 260
                color: "transparent"
                visible: false

                Rectangle {
                    anchors.fill: parent
                    color: root.palette.base
                    radius: 8
                    border.color: root.palette.lavender
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Row {
                            width: parent.width
                            height: 20

                            Text {
                                id: prevBtn
                                width: 24
                                height: parent.height
                                text: "<"
                                color: root.palette.muted
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.shiftMonth(-1)
                                    onEntered: prevBtn.color = root.palette.cyan
                                    onExited: prevBtn.color = root.palette.muted
                                    hoverEnabled: true
                                }
                            }

                            Text {
                                width: parent.width - 48
                                height: parent.height
                                text: {
                                    const months = ["January","February","March","April","May","June",
                                                    "July","August","September","October","November","December"];
                                    return months[panel.viewMonth] + " " + panel.viewYear;
                                }
                                color: root.palette.violet
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                id: nextBtn
                                width: 24
                                height: parent.height
                                text: ">"
                                color: root.palette.muted
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.shiftMonth(1)
                                    onEntered: nextBtn.color = root.palette.cyan
                                    onExited: nextBtn.color = root.palette.muted
                                    hoverEnabled: true
                                }
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 0

                            Repeater {
                                model: ["Su","Mo","Tu","We","Th","Fr","Sa"]
                                delegate: Text {
                                    required property string modelData
                                    width: (parent.width) / 7
                                    text: modelData
                                    color: root.palette.muted
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize - 2
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        Grid {
                            id: dayGrid
                            width: parent.width
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 0

                            property var cells: {
                                const first = new Date(panel.viewYear, panel.viewMonth, 1).getDay();
                                const days = new Date(panel.viewYear, panel.viewMonth + 1, 0).getDate();
                                const today = clockTick.now;
                                const isCurrentMonth =
                                    today.getFullYear() === panel.viewYear &&
                                    today.getMonth() === panel.viewMonth;
                                const todayDate = today.getDate();
                                const out = [];
                                for (let i = 0; i < 42; i++) {
                                    const d = i - first + 1;
                                    out.push({
                                        day: (d >= 1 && d <= days) ? d : 0,
                                        isToday: isCurrentMonth && d === todayDate
                                    });
                                }
                                return out;
                            }

                            Repeater {
                                model: dayGrid.cells
                                delegate: Item {
                                    required property var modelData
                                    width: dayGrid.width / 7
                                    height: 22

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        radius: 11
                                        visible: modelData.isToday
                                        color: "transparent"
                                        border.color: root.palette.cyan
                                        border.width: 1
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.day > 0 ? modelData.day : ""
                                        color: modelData.isToday
                                            ? root.palette.cyan
                                            : root.palette.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: root.fontSize - 1
                                        font.bold: modelData.isToday
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: launcher
            required property var modelData
            screen: modelData

            readonly property bool isFocusedScreen:
                Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name

            visible: root.launcherVisible && isFocusedScreen
            focusable: true
            color: "#a0000000"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            property var results: root.filterApps("")
            property int selectedIndex: 0

            onVisibleChanged: {
                if (visible) {
                    searchField.text = "";
                    selectedIndex = 0;
                    results = root.filterApps("");
                    searchField.forceActiveFocus();
                }
            }

            function runSelected() {
                if (selectedIndex < 0 || selectedIndex >= results.length) return;
                const entry = results[selectedIndex];
                if (entry.execute) entry.execute();
                else if (entry.command) Quickshell.execDetached(entry.command);
                root.launcherVisible = false;
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.launcherVisible = false
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.max(80, parent.height * 0.2)
                width: 560
                height: 440
                color: root.palette.base
                radius: 10
                border.color: root.palette.lavender
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 36
                        color: root.palette.surface
                        radius: 6
                        border.color: searchField.activeFocus ? root.palette.cyan : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                color: root.palette.violet
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize + 2
                            }

                            TextInput {
                                id: searchField
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 40
                                color: root.palette.fg
                                selectionColor: root.palette.lavender
                                selectedTextColor: root.palette.base
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize + 1
                                focus: true
                                clip: true

                                property string placeholderText: "run..."

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: searchField.placeholderText
                                    color: root.palette.muted
                                    font: searchField.font
                                    visible: !searchField.text && !searchField.activeFocus
                                }

                                onTextChanged: {
                                    launcher.results = root.filterApps(text);
                                    launcher.selectedIndex = 0;
                                }

                                Keys.onEscapePressed: root.launcherVisible = false
                                Keys.onReturnPressed: launcher.runSelected()
                                Keys.onEnterPressed: launcher.runSelected()
                                Keys.onUpPressed: {
                                    if (launcher.selectedIndex > 0) launcher.selectedIndex--;
                                }
                                Keys.onDownPressed: {
                                    if (launcher.selectedIndex < launcher.results.length - 1)
                                        launcher.selectedIndex++;
                                }
                            }
                        }
                    }

                    ListView {
                        id: resultsList
                        width: parent.width
                        height: parent.height - 46
                        model: launcher.results
                        currentIndex: launcher.selectedIndex
                        clip: true
                        spacing: 2
                        highlightMoveDuration: 80
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 38
                            radius: 6
                            color: index === launcher.selectedIndex
                                ? root.palette.surface
                                : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                radius: 2
                                color: index === launcher.selectedIndex
                                    ? root.palette.violet
                                    : "transparent"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 10
                                spacing: 12

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 22
                                    height: 22
                                    source: modelData.icon
                                        ? Quickshell.iconPath(modelData.icon, true) || ""
                                        : ""
                                    sourceSize.width: 44
                                    sourceSize.height: 44
                                    visible: status === Image.Ready
                                    asynchronous: true
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 44
                                    spacing: 1

                                    Text {
                                        width: parent.width
                                        text: modelData.name || ""
                                        color: root.palette.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: root.fontSize
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.genericName || modelData.comment || ""
                                        color: root.palette.muted
                                        font.family: root.fontFamily
                                        font.pixelSize: root.fontSize - 3
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: launcher.selectedIndex = index
                                onClicked: launcher.runSelected()
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: clipboard
            required property var modelData
            screen: modelData

            readonly property bool isFocusedScreen:
                Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name

            visible: root.clipboardVisible && isFocusedScreen
            focusable: true
            color: "#a0000000"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            function filterClip(query) {
                const entries = root.clipEntries || [];
                if (!query) return entries.slice(0, 100);
                const q = query.toLowerCase();
                return entries.filter(e => (e.preview || "").toLowerCase().indexOf(q) >= 0).slice(0, 100);
            }

            property var results: filterClip("")
            property int selectedIndex: 0

            onVisibleChanged: {
                if (visible) {
                    root.reloadClipboard();
                    clipSearch.text = "";
                    selectedIndex = 0;
                    results = filterClip("");
                    clipSearch.forceActiveFocus();
                }
            }

            Connections {
                target: root
                function onClipEntriesChanged() {
                    clipboard.results = clipboard.filterClip(clipSearch.text);
                    if (clipboard.selectedIndex >= clipboard.results.length)
                        clipboard.selectedIndex = Math.max(0, clipboard.results.length - 1);
                }
            }

            function pickSelected() {
                if (selectedIndex < 0 || selectedIndex >= results.length) return;
                root.pickClip(results[selectedIndex]);
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.clipboardVisible = false
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.max(80, parent.height * 0.2)
                width: 640
                height: 480
                color: root.palette.base
                radius: 10
                border.color: root.palette.lavender
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 36
                        color: root.palette.surface
                        radius: 6
                        border.color: clipSearch.activeFocus ? root.palette.cyan : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                color: root.palette.violet
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize + 2
                            }

                            TextInput {
                                id: clipSearch
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 40
                                color: root.palette.fg
                                selectionColor: root.palette.lavender
                                selectedTextColor: root.palette.base
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize + 1
                                focus: true
                                clip: true

                                property string placeholderText: "filter clipboard..."

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: clipSearch.placeholderText
                                    color: root.palette.muted
                                    font: clipSearch.font
                                    visible: !clipSearch.text && !clipSearch.activeFocus
                                }

                                onTextChanged: {
                                    clipboard.results = clipboard.filterClip(text);
                                    clipboard.selectedIndex = 0;
                                }

                                Keys.onEscapePressed: root.clipboardVisible = false
                                Keys.onReturnPressed: clipboard.pickSelected()
                                Keys.onEnterPressed: clipboard.pickSelected()
                                Keys.onUpPressed: {
                                    if (clipboard.selectedIndex > 0) clipboard.selectedIndex--;
                                }
                                Keys.onDownPressed: {
                                    if (clipboard.selectedIndex < clipboard.results.length - 1)
                                        clipboard.selectedIndex++;
                                }
                            }
                        }
                    }

                    ListView {
                        id: clipList
                        width: parent.width
                        height: parent.height - 46
                        model: clipboard.results
                        currentIndex: clipboard.selectedIndex
                        clip: true
                        spacing: 2
                        highlightMoveDuration: 80
                        boundsBehavior: Flickable.StopAtBounds

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 34
                            radius: 6
                            color: index === clipboard.selectedIndex
                                ? root.palette.surface
                                : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                radius: 2
                                color: index === clipboard.selectedIndex
                                    ? root.palette.violet
                                    : "transparent"
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 14
                                anchors.rightMargin: 10
                                text: root.clipPreview(modelData)
                                color: root.palette.fg
                                font.family: root.fontFamily
                                font.pixelSize: root.fontSize
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: clipboard.selectedIndex = index
                                onClicked: clipboard.pickSelected()
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: clipboard.results.length === 0
                                ? (root.clipEntries.length === 0 ? "no clipboard history" : "no matches")
                                : ""
                            color: root.palette.muted
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            visible: clipboard.results.length === 0
                        }
                    }
                }
            }
        }
    }
}
