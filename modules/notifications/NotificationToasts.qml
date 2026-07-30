pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    PanelWindow {
        id: toastWindow

        // Negative values move the notification stack upward; positive
        // values move it downward.
        readonly property int verticalOffset: -Appearance.px(40)

        screen: Quickshell.screens.length > 0
            ? Quickshell.screens[0] : null
        visible: NotificationService.popupEntries.length > 0
            && !NotificationService.doNotDisturb
        color: "transparent"
        implicitWidth: Appearance.px(435)
        exclusiveZone: 0

        anchors {
            top: true
            right: true
            bottom: true
        }

        WlrLayershell.namespace: "quickshell:notification-toasts"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            item: toastColumn
        }

        Column {
            id: toastColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Appearance.barHeight
                    + toastWindow.verticalOffset
                rightMargin: Appearance.px(5)
            }
            spacing: Appearance.px(4)

            Repeater {
                model: NotificationService.popupEntries

                delegate: NotificationToastCard {
                    required property var modelData
                    width: toastColumn.width
                    notificationEntry: modelData
                }
            }
        }
    }
}
