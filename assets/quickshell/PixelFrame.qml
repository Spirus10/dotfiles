import QtQuick

// A bordered segment with a soft pixel-glow around it. Stepped corners
// are approximated with a small radius to preserve the retro look while
// still reading as "rounded" at 1x DPR.
Item {
    id: root

    property color fillColor:   Theme.bgFrame
    property color borderColor: Theme.magenta
    property color glowColor:   Theme.magenta
    property int   borderWidth: Theme.frameBorder
    property int   frameRadius: Theme.frameRadius
    property int   contentPadding: Theme.frameContentPad
    property bool  showGlow: false

    // The slot children get parented into — consumers just write children
    // as if this were a plain Item.
    default property alias data: content.data

    // --- outer glow layers (sharp, decreasing alpha) -----------------
    Rectangle {
        visible: root.showGlow
        anchors.fill: parent
        anchors.margins: -4
        color: "transparent"
        border.color: root.glowColor
        border.width: 1
        opacity: 0.07
        radius: root.frameRadius + 3
        antialiasing: false
    }
    Rectangle {
        visible: root.showGlow
        anchors.fill: parent
        anchors.margins: -2
        color: "transparent"
        border.color: root.glowColor
        border.width: 1
        opacity: 0.18
        radius: root.frameRadius + 1
        antialiasing: false
    }

    // --- main frame ---------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: root.fillColor
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.frameRadius
        antialiasing: false
    }

    // --- content slot -------------------------------------------------
    Item {
        id: content
        anchors.fill: parent
        anchors.leftMargin:   root.contentPadding
        anchors.rightMargin:  root.contentPadding
        anchors.topMargin:    root.borderWidth + 2
        anchors.bottomMargin: root.borderWidth + 2
    }
}
