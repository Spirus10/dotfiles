import QtQuick
import QtQuick.Layouts
import Quickshell

// Top bar: a blue-gradient chassis with magenta outline, segmented into
// workspaces (left) | media (center) | volume + clock (right). The bar
// material shows between pockets, decorated with small cyan "+" sparkles.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    // --- bar chassis (the whole blue strip with magenta border) ---------
    BarChrome {
        id: chrome
        anchors.fill: parent
    }

    // --- segment row ---------------------------------------------------
    // Sits inside the chrome; each PixelFrame is a dark "pocket" cut into
    // the bar. Sparkles between segments keep the bar material visible.
    RowLayout {
        anchors.fill: chrome
        anchors.margins: Theme.frameBorder + 3
        spacing: 0

        PixelFrame {
            id: wsFrame
            Layout.fillHeight: true
            Layout.preferredWidth: wsContent.implicitWidth + wsFrame.contentPadding * 2
            contentPadding: 10
            borderWidth: 2

            Workspaces {
                id: wsContent
                anchors.centerIn: parent
            }
        }

        Sparkle { Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 8; Layout.rightMargin: 8 }

        // Stretch spacer — centers the media pocket even when left/right
        // clusters differ in width.
        Item { Layout.fillWidth: true }

        PixelFrame {
            id: mediaFrame
            Layout.fillHeight: true
            Layout.preferredWidth: mediaContent.implicitWidth + mediaFrame.contentPadding * 2
            contentPadding: 12
            borderWidth: 2

            MediaPlayer {
                id: mediaContent
                anchors.centerIn: parent
            }
        }

        Item { Layout.fillWidth: true }

        Sparkle { Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 8; Layout.rightMargin: 8 }

        PixelFrame {
            id: volumeFrame
            Layout.fillHeight: true
            Layout.preferredWidth: volumeContent.implicitWidth + volumeFrame.contentPadding * 2
            contentPadding: 10
            borderWidth: 2

            VolumeIndicator {
                id: volumeContent
                anchors.centerIn: parent
            }
        }

        Sparkle { Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 8; Layout.rightMargin: 8 }

        PixelFrame {
            id: clockFrame
            Layout.fillHeight: true
            Layout.preferredWidth: clockContent.implicitWidth + clockFrame.contentPadding * 2
            contentPadding: 12
            borderWidth: 2

            Clock {
                id: clockContent
                anchors.centerIn: parent
            }
        }
    }
}
