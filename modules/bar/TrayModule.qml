pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import qs.common

MouseArea {
    id: root

    signal activated

    property bool expanded: false
    readonly property bool needsAttention:
        SystemTray.items.values.some(item =>
            item?.status === Status.NeedsAttention)

    implicitWidth: Appearance.px(30)
    implicitHeight: Appearance.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()

    Rectangle {
        width: Appearance.px(30)
        height: Appearance.px(30)
        anchors.centerIn: parent
        radius: Appearance.fullRadius
        color: root.containsMouse || root.expanded
            ? Appearance.layer1Hover
            : Appearance.withAlpha(Appearance.layer1Hover, 0)
        scale: root.pressed ? 0.88 : 1

        Text {
            anchors.centerIn: parent
            text: ""
            rotation: root.expanded ? 180 : 0
            color: root.needsAttention
                ? Appearance.primary : Appearance.layer0Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.px(11)
                weight: Font.Bold
            }

            Behavior on rotation {
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            visible: root.needsAttention
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Appearance.px(4)
                rightMargin: Appearance.px(4)
            }
            width: Appearance.px(6)
            height: width
            radius: width / 2
            color: Appearance.tertiary
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
