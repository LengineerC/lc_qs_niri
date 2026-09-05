pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import qs.common

// Shared in-shell tooltip. Avoids falling back to the platform Controls style
// (for example the square yellow tooltip from the native desktop theme).
Controls.ToolTip {
    id: root

    property bool showBelow: true
    property int gap: Appearance.px(5)

    x: Math.round((parent.width - width) / 2)
    y: root.showBelow ? parent.height + root.gap
        : -height - root.gap
    z: 10000

    delay: 450
    timeout: -1
    padding: Appearance.px(8)
    topPadding: Appearance.px(5)
    bottomPadding: Appearance.px(5)

    contentItem: AppText {
        text: root.text
        color: Appearance.layer0Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.smallFontSize
            weight: Font.Medium
        }
    }

    background: Rectangle {
        radius: Appearance.px(8)
        color: Appearance.layer3
        border.width: 1
        border.color: Appearance.outline
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.94
                to: 1
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.fastDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.97
                duration: Appearance.fastDuration
                easing.type: Easing.InCubic
            }
        }
    }
}
