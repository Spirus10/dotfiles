pragma Singleton

import QtQuick

QtObject {
    // Base surface — deep violet/black from the concept art.
    readonly property color bg:         "#0d0418"
    readonly property color bgFrame:    "#0a0414"   // very dark pocket fill

    // The bar chassis itself — blue→purple gradient with a cyan top rim.
    readonly property color barBlueTop:     "#2f4c8c"
    readonly property color barBlueMid:     "#283f78"
    readonly property color barPurpleBot:   "#3b1e5e"
    readonly property color barTopRim:      "#22c4dd"

    // Neon magenta — primary border / glow.
    readonly property color magenta:        "#ff4ec9"
    readonly property color magentaDim:     "#8a2a7a"
    readonly property color magentaGlow:    "#ff88e0"

    // Neon cyan — secondary accent used for icons and some text.
    readonly property color cyan:           "#22e6e6"
    readonly property color cyanDim:        "#187a85"
    readonly property color cyanGlow:       "#88f5f5"

    // Teal highlight seen on the clock / media labels.
    readonly property color teal:           "#00ffcc"

    // Foreground text tones.
    readonly property color text:           "#e4c9ff"
    readonly property color textDim:        "#7a5e9a"
    readonly property color textInverse:    "#0d0418"

    // Geometry.
    readonly property int barHeight:        44
    readonly property int barPadding:       6
    readonly property int frameBorder:      2
    readonly property int frameRadius:      3        // 2-3 px keeps the stepped-pixel look
    readonly property int frameContentPad:  10
    readonly property int segmentSpacing:   6

    // Fonts — prefer an installed pixel font, fall back to monospace so
    // the bar still runs if none are installed. See README for suggestions.
    readonly property string pixelFont:      "Press Start 2P"
    readonly property string pixelFontBody:  "PixelOperator"
    readonly property int   pixelSize:       10
    readonly property int   pixelSizeSmall:  8
    readonly property int   pixelSizeClock:  14
    readonly property int   pixelSizeBody:   14
}
