pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested
    property bool active: visible
    property bool contentReady: false

    onActiveChanged: {
        contentDelay.stop();
        contentReady = false;
        if (active)
            contentDelay.start();
    }

    Timer {
        id: contentDelay
        interval: Appearance.spatialDuration + 40
        repeat: false
        onTriggered: {
            if (root.active)
                root.contentReady = true;
        }
    }

    component PanelText: AppText {
        color: Appearance.barLayer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component HeaderButton: ActionButton {
        useBarPalette: true
        compact: true
        outlined: true
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.panelPadding
        }
        spacing: Appearance.spacingSmall

        PopupHeader {
            useBarPalette: true
            icon: NotificationService.doNotDisturb ? "󰂛" : "󰂚"
            iconSize: Appearance.px(19)
            title: I18n.tr("notifications")
            contentSpacing: Appearance.spacingSmall
            dividerSpacing: Appearance.spacingSmall
            dividerOpacity: 1
            onCloseClicked: root.closeRequested()

            HeaderButton {
                icon: NotificationService.doNotDisturb ? "󰂚" : "󰂛"
                label: I18n.tr("doNotDisturb")
                onClicked: {
                    ShellSettings.doNotDisturb =
                        !ShellSettings.doNotDisturb;
                }
            }

            HeaderButton {
                icon: "󰄬"
                label: I18n.tr("markAllRead")
                enabled: NotificationService.unreadCount > 0
                opacity: enabled ? 1 : 0.4
                onClicked: NotificationService.markAllRead()
            }
        }

        ListView {
            id: notificationList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacingSmall
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 0
            reuseItems: true

            // Do not instantiate notification-center cards while another
            // popup page is visible. A ListView also keeps work bounded to
            // the handful of cards near the viewport.
            model: root.contentReady
                ? NotificationService.centerEntries : []

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            header: ColumnLayout {
                width: notificationList.width - Appearance.px(8)
                spacing: Appearance.spacingSmall

                PanelText {
                    Layout.fillWidth: true
                    text: I18n.tr("unreadNotifications")
                        + "  " + NotificationService.unreadCount
                    color: Appearance.barLayer0Text
                    font.weight: Font.DemiBold
                }

                PanelText {
                    visible: NotificationService.unreadCount === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(8)
                    Layout.bottomMargin: Appearance.px(8)
                    horizontalAlignment: Text.AlignHCenter
                    text: I18n.tr("noUnreadNotifications")
                    color: Appearance.barSubtext
                }
            }

            delegate: Column {
                id: notificationDelegate

                required property var modelData
                required property int index

                readonly property bool firstHistory: {
                    if (!modelData.read || index < 0)
                        return false;
                    if (index === 0)
                        return true;
                    const previous = NotificationService
                        .centerEntries[index - 1];
                    return !previous || !previous.read;
                }

                width: notificationList.width - Appearance.px(8)
                spacing: Appearance.spacingSmall

                Rectangle {
                    visible: notificationDelegate.firstHistory
                    width: parent.width
                    height: visible ? 1 : 0
                    color: Appearance.barOutline
                }

                RowLayout {
                    visible: notificationDelegate.firstHistory
                    width: parent.width

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("notificationHistory")
                            + "  "
                            + NotificationService.historyEntries.length
                        color: Appearance.barLayer0Text
                        font.weight: Font.DemiBold
                    }

                    HeaderButton {
                        icon: "󰆴"
                        label: I18n.tr("clearHistory")
                        destructive: true
                        onClicked: NotificationService.clearHistory()
                    }
                }

                NotificationCenterCard {
                    width: parent.width
                    notificationEntry: notificationDelegate.modelData
                    historical: notificationDelegate.modelData.read
                    onActivated: NotificationService.activate(
                        notificationDelegate.modelData)
                    onSecondaryAction: {
                        if (notificationDelegate.modelData.read) {
                            NotificationService.removeEntry(
                                notificationDelegate.modelData.notificationId);
                        } else {
                            NotificationService.markRead(
                                notificationDelegate.modelData.notificationId);
                        }
                    }
                }
            }

            footer: Item {
                visible: NotificationService.historyEntries.length === 0
                width: notificationList.width - Appearance.px(8)
                height: visible ? emptyHistory.implicitHeight : 0

                ColumnLayout {
                    id: emptyHistory
                    width: parent.width
                    spacing: Appearance.spacingSmall

                    Rectangle {
                        visible: NotificationService.unreadCount > 0
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.px(5)
                        implicitHeight: 1
                        color: Appearance.barOutline
                    }

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("notificationHistory") + "  0"
                        color: Appearance.barLayer0Text
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.px(8)
                        horizontalAlignment: Text.AlignHCenter
                        text: I18n.tr("noNotificationHistory")
                        color: Appearance.barSubtext
                    }
                }
            }
        }
    }
}
