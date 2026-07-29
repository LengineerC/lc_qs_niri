pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// Shared close affordance for popups and settings pages.
Rectangle {
    id: root

    signal clicked

    property color iconColor: Appearance.subtext
    property color hoverColor: Appearance.layer1Active

    implicitWidth: Appearance.px(28)
    implicitHeight: Appearance.px(28)
    radius: Appearance.fullRadius
    color: closeMouse.containsMouse && root.enabled
        ? root.hoverColor : "transparent"
    scale: closeMouse.pressed ? 0.88 : 1
    opacity: root.enabled ? 1 : 0.4

    Text {
        anchors.centerIn: parent
        text: "󰅖"
        color: root.iconColor
        font {
            family: Appearance.iconFontFamily
            pixelSize: Appearance.px(15)
        }
    }

    MouseArea {
        id: closeMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled
            ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
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

    Behavior on opacity {
        NumberAnimation { duration: Appearance.fastDuration }
    }
}
