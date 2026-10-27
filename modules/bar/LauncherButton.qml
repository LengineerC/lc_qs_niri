pragma ComponentBehavior: Bound

import QtQuick
import qs.common

MouseArea {
    id: root

    property bool active: false
    signal activated
    signal sidebarRequested

    implicitWidth: Appearance.px(30)
    implicitHeight: Appearance.barHeight
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: event => {
        if (event.button === Qt.RightButton)
            sidebarRequested();
        else
            activated();
    }

    Rectangle {
        id: launcherPill
        width: Appearance.px(30)
        height: Appearance.px(30)
        anchors.centerIn: parent
        radius: Appearance.fullRadius
        color: root.containsMouse || root.active ? Appearance.barSecondaryContainer : Appearance.withAlpha(Appearance.barSecondaryContainer, 0)
        scale: root.pressed ? 0.88 : 1

        AppText {
            anchors.centerIn: parent
            text: "✦"
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.px(21)
            }
        }

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
