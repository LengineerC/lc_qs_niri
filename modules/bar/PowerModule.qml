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
            ? Appearance.primaryContainer
            : Appearance.withAlpha(Appearance.primaryContainer, 0)
        scale: root.pressed ? 0.88 : 1

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: root.containsMouse
                ? Appearance.primaryContainerText : Appearance.layer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(17)
            }
        }

        Behavior on color {
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
