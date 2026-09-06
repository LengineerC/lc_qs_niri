pragma ComponentBehavior: Bound

import QtQuick
import qs.common

Item {
    id: root

    required property bool checked
    property bool useBarPalette: false
    signal toggled(bool checked)

    implicitWidth: Appearance.switchWidth
    implicitHeight: Appearance.switchHeight
    opacity: enabled ? 1 : 0.4

    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.fullRadius
        color: root.checked ? palette.primary : palette.layer1Active
        border.width: root.checked ? 0 : 1
        border.color: palette.subtext

        Rectangle {
            width: root.checked ? Appearance.px(19) : Appearance.px(15)
            height: width
            radius: Appearance.fullRadius
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked
                ? parent.width - width - Appearance.px(3)
                : Appearance.px(5)
            color: root.checked ? palette.onPrimary : palette.subtext

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }
}
