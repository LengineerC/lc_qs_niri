pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.common
import qs.services

Item {
    id: root

    required property var notificationEntry
    property real implicitSize: Appearance.px(44)
    property real iconPadding: Appearance.px(5)

    readonly property bool hasProfileImage:
        NotificationService.hasNotificationImage(notificationEntry)
    readonly property bool hasAppBadge:
        hasProfileImage
            && NotificationService.hasApplicationIcon(notificationEntry)

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    ClippingRectangle {
        id: avatarClip

        anchors.fill: parent
        radius: Appearance.fullRadius
        color: Appearance.primaryContainer
        clip: true

        Image {
            anchors {
                fill: parent
                margins: root.hasProfileImage ? 0 : root.iconPadding
            }
            asynchronous: true
            cache: false
            sourceSize {
                width: width
                height: height
            }
            source: NotificationService.avatarSource(
                root.notificationEntry)
            fillMode: root.hasProfileImage
                ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        }
    }

    Rectangle {
        visible: root.hasAppBadge
        width: Math.max(Appearance.px(16), root.implicitSize * 0.4)
        height: width
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        radius: Appearance.fullRadius
        color: Appearance.layer1
        border.width: 1
        border.color: Appearance.outline

        IconImage {
            anchors {
                fill: parent
                margins: Appearance.px(2)
            }
            asynchronous: true
            source: NotificationService.iconSource(
                root.notificationEntry)
        }
    }
}
