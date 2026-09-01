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

        // Describe every card in window coordinates. Unlike Region.item,
        // these rectangles avoid the transformed-item overflow bug, but
        // explicitly follow each delegate while it slides. Keeping separate
        // regions also leaves the space between cards untouched.
        BackgroundEffect.blurRegion: Region {
            Region {
                x: toastColumn.x
                    + (toastRepeater.count > 0
                        ? (toastRepeater.itemAt(0)?.x ?? 0) : 0)
                    + Appearance.px(8)
                y: toastColumn.y
                    + (toastRepeater.count > 0
                        ? (toastRepeater.itemAt(0)?.y ?? 0)
                            + Appearance.px(8) : 0)
                width: ShellSettings.barFrostedGlass
                        && toastRepeater.count > 0
                    ? toastColumn.width - Appearance.px(16) : 0
                height: width > 0
                    ? (toastRepeater.itemAt(0)?.blurSurfaceHeight ?? 0) : 0
                radius: Appearance.normalRadius
            }
            Region {
                x: toastColumn.x
                    + (toastRepeater.count > 1
                        ? (toastRepeater.itemAt(1)?.x ?? 0) : 0)
                    + Appearance.px(8)
                y: toastColumn.y
                    + (toastRepeater.count > 1
                        ? (toastRepeater.itemAt(1)?.y ?? 0)
                            + Appearance.px(8) : 0)
                width: ShellSettings.barFrostedGlass
                        && toastRepeater.count > 1
                    ? toastColumn.width - Appearance.px(16) : 0
                height: width > 0
                    ? (toastRepeater.itemAt(1)?.blurSurfaceHeight ?? 0) : 0
                radius: Appearance.normalRadius
            }
            Region {
                x: toastColumn.x
                    + (toastRepeater.count > 2
                        ? (toastRepeater.itemAt(2)?.x ?? 0) : 0)
                    + Appearance.px(8)
                y: toastColumn.y
                    + (toastRepeater.count > 2
                        ? (toastRepeater.itemAt(2)?.y ?? 0)
                            + Appearance.px(8) : 0)
                width: ShellSettings.barFrostedGlass
                        && toastRepeater.count > 2
                    ? toastColumn.width - Appearance.px(16) : 0
                height: width > 0
                    ? (toastRepeater.itemAt(2)?.blurSurfaceHeight ?? 0) : 0
                radius: Appearance.normalRadius
            }
            Region {
                x: toastColumn.x
                    + (toastRepeater.count > 3
                        ? (toastRepeater.itemAt(3)?.x ?? 0) : 0)
                    + Appearance.px(8)
                y: toastColumn.y
                    + (toastRepeater.count > 3
                        ? (toastRepeater.itemAt(3)?.y ?? 0)
                            + Appearance.px(8) : 0)
                width: ShellSettings.barFrostedGlass
                        && toastRepeater.count > 3
                    ? toastColumn.width - Appearance.px(16) : 0
                height: width > 0
                    ? (toastRepeater.itemAt(3)?.blurSurfaceHeight ?? 0) : 0
                radius: Appearance.normalRadius
            }
            Region {
                x: toastColumn.x
                    + (toastRepeater.count > 4
                        ? (toastRepeater.itemAt(4)?.x ?? 0) : 0)
                    + Appearance.px(8)
                y: toastColumn.y
                    + (toastRepeater.count > 4
                        ? (toastRepeater.itemAt(4)?.y ?? 0)
                            + Appearance.px(8) : 0)
                width: ShellSettings.barFrostedGlass
                        && toastRepeater.count > 4
                    ? toastColumn.width - Appearance.px(16) : 0
                height: width > 0
                    ? (toastRepeater.itemAt(4)?.blurSurfaceHeight ?? 0) : 0
                radius: Appearance.normalRadius
            }
        }

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
                id: toastRepeater

                // A plain JavaScript array resets every delegate whenever a
                // toast is removed. ScriptModel diffs entries by their stable
                // id, preserving the other cards and their loaded avatars.
                model: ScriptModel {
                    values: NotificationService.popupEntries
                    objectProp: "notificationId"
                }

                delegate: NotificationToastCard {
                    required property var modelData
                    width: toastColumn.width
                    notificationEntry: modelData
                }
            }
        }
    }
}
