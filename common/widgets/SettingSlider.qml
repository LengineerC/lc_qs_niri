pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import qs.common

Controls.Slider {
    id: root

    property bool useBarPalette: false

    implicitHeight: Appearance.compactControlHeight

    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: Appearance.px(6)
        radius: Appearance.fullRadius
        color: palette.layer1Active
        border.width: 1
        border.color: Appearance.withAlpha(palette.outline, 0.65)

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.enabled ? palette.primary : palette.subtext
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition
            * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: Appearance.px(root.pressed ? 11 : 15)
        implicitHeight: Appearance.px(22)
        radius: Appearance.fullRadius
        color: root.enabled ? palette.primary : palette.subtext

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
