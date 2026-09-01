pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.services

MouseArea {
    id: root

    signal activated

    implicitWidth: Appearance.px(34)
    implicitHeight: Appearance.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: event => {
        if (event.button === Qt.RightButton) {
            if (NotificationService.unreadCount > 0) {
                NotificationService.markAllRead();
            }
        } else {
            activated();
        }
    }

    Rectangle {
        width: Appearance.px(30)
        height: Appearance.px(30)
        anchors.centerIn: parent
        radius: Appearance.fullRadius
        color: root.containsMouse
            ? Appearance.barLayer1Hover
            : Appearance.withAlpha(Appearance.barLayer1Hover, 0)
        scale: root.pressed ? 0.88 : 1

        Text {
            anchors.centerIn: parent
            text: NotificationService.doNotDisturb
                ? "󰂛"
                : NotificationService.unreadCount > 0
                    ? "󰂞" : "󰂚"
            color: NotificationService.unreadCount > 0
                    && !NotificationService.doNotDisturb
                ? Appearance.barPrimary : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(17)
            }
        }

        Rectangle {
            visible: NotificationService.unreadCount > 0
                && !NotificationService.doNotDisturb
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Appearance.px(1)
                rightMargin: Appearance.px(1)
            }
            width: Math.max(Appearance.px(9),
                unreadText.implicitWidth + Appearance.px(4))
            height: Appearance.px(9)
            radius: Appearance.fullRadius
            color: Appearance.barTertiary

            Text {
                id: unreadText
                anchors.centerIn: parent
                text: NotificationService.unreadCount > 99
                    ? "99+" : NotificationService.unreadCount
                color: Appearance.barOnPrimary
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(6)
                    weight: Font.Bold
                }
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
