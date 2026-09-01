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
    property bool profileImageReady: false

    readonly property bool hasProfileImage:
        NotificationService.hasNotificationImage(notificationEntry)
    readonly property bool hasAppBadge:
        hasProfileImage
            && NotificationService.hasApplicationIcon(notificationEntry)

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    function prepareProfileImage() {
        profileImageReady = false;
        imageDelay.stop();
        if (hasProfileImage)
            imageDelay.start();
    }

    onNotificationEntryChanged: prepareProfileImage()
    onHasProfileImageChanged: prepareProfileImage()
    Component.onCompleted: prepareProfileImage()

    Timer {
        id: imageDelay
        // Screenshot tools may emit the notification just before the image
        // file has finished being written.
        interval: 180
        repeat: false
        onTriggered: root.profileImageReady = true
    }

    ClippingRectangle {
        id: avatarClip

        anchors.fill: parent
        radius: Appearance.fullRadius
        color: ShellSettings.barFrostedGlass
            ? Appearance.barLayer1Active : Appearance.primaryContainer
        clip: true

        Text {
            anchors.centerIn: parent
            visible: avatarImage.status === Image.Error
                || !root.hasProfileImage
                    && avatarImage.status !== Image.Ready
            text: "󰂚"
            color: ShellSettings.barFrostedGlass
                ? Appearance.barPrimary : Appearance.primary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Math.round(root.implicitSize * 0.48)
            }
        }

        Image {
            id: avatarImage

            anchors {
                fill: parent
                margins: root.hasProfileImage ? 0 : root.iconPadding
            }
            // File thumbnails decode off the GUI thread. Theme icons stay on
            // the GUI thread because concurrent QIcon::fromTheme calls can
            // crash in Qt's icon loader under a notification burst.
            asynchronous: root.hasProfileImage
            cache: !root.hasProfileImage
            retainWhileLoading: false
            sourceSize {
                width: width
                height: height
            }
            source: root.hasProfileImage && !root.profileImageReady
                ? "" : NotificationService.avatarSource(
                    root.notificationEntry)
            visible: status === Image.Ready
            fillMode: root.hasProfileImage
                ? Image.PreserveAspectCrop : Image.PreserveAspectFit

            onStatusChanged: {
                if (status === Image.Error && root.hasProfileImage) {
                    NotificationService.invalidateImage(
                        root.notificationEntry, source);
                }
            }
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
        color: ShellSettings.barFrostedGlass
            ? Appearance.barGlassBaseColor : Appearance.layer1
        border.width: 1
        border.color: ShellSettings.barFrostedGlass
            ? Appearance.barOutline : Appearance.outline

        IconImage {
            anchors {
                fill: parent
                margins: Appearance.px(2)
            }
            // See avatarImage above: avoid concurrent QIcon theme lookups.
            asynchronous: false
            source: NotificationService.iconSource(
                root.notificationEntry)
        }
    }
}
