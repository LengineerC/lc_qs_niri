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
        color: root.containsMouse
            ? Appearance.barPrimaryContainer
            : Appearance.withAlpha(Appearance.barPrimaryContainer, 0)
        scale: root.pressed ? 0.88 : 1

        AppText {
            anchors.centerIn: parent
            text: "󰐥"
            color: root.containsMouse
                ? Appearance.barPrimaryContainerText : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
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
