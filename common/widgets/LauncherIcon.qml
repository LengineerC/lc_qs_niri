pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.common

// Preserve each application's silhouette; selection belongs to the launcher.
Item {
    id: root

    property string iconName: ""
    property real iconSize: Appearance.px(64)
    property bool hovered: false
    property bool pressed: false

    implicitWidth: iconSize
    implicitHeight: iconSize
    scale: pressed ? 0.92 : hovered ? 1.06 : 1

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(root.iconName, "application-x-executable")
        asynchronous: true
        opacity: ShellSettings.monochromeAppIconsActive
            ? Appearance.monochromeAppIconOpacity : 1
        layer.enabled: ShellSettings.monochromeAppIconsActive
        layer.effect: MultiEffect {
            saturation: -1
            brightness: 0.12
            contrast: 0.08
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.fastDuration
            easing.type: Easing.OutCubic
        }
    }
}
