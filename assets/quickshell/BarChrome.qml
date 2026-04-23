import QtQuick

// The bar chassis: blue-to-purple vertical gradient with a magenta
// outer border and a 1px cyan top rim. Pockets (PixelFrames) sit
// inside this; the bar material shows through between them.
Rectangle {
    id: root

    antialiasing: false
    radius: Theme.frameRadius + 1
    border.color: Theme.magenta
    border.width: Theme.frameBorder

    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.00; color: Theme.barBlueTop }
        GradientStop { position: 0.55; color: Theme.barBlueMid }
        GradientStop { position: 1.00; color: Theme.barPurpleBot }
    }

    // 1px cyan top rim just inside the border — reads as a light source
    // glancing off the top edge of a physical sign.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.border.width
        anchors.leftMargin: root.border.width + root.radius
        anchors.rightMargin: root.border.width + root.radius
        height: 1
        color: Theme.barTopRim
        opacity: 0.75
        antialiasing: false
    }
}
