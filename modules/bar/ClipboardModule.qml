pragma ComponentBehavior: Bound

import QtQuick
import qs.common

MouseArea {
    id: root

    signal activated

    implicitWidth: Appearance.px(30)
    implicitHeight: Appearance.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()

    Rectangle {
        width: Appearance.px(30)
        height: Appearance.px(30)
        anchors.verticalCenter: parent.verticalCenter
        radius: Appearance.fullRadius
        color: ShellSettings.barBackgroundless
            ? "transparent"
            : root.containsMouse
            ? Appearance.barLayer1Hover
            : Appearance.withAlpha(Appearance.barLayer1Hover, 0)
        scale: root.pressed ? 0.88 : 1

        Text {
            anchors.centerIn: parent
            text: "󰅇"
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(17)
            }
        }

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation { duration: Appearance.fastDuration }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
