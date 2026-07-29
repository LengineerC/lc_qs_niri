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

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component HeaderButton: Rectangle {
        id: button

        required property string icon
        property string label: ""
        property bool destructive: false
        signal clicked

        implicitWidth: buttonRow.implicitWidth + Appearance.px(16)
        implicitHeight: Appearance.px(30)
        radius: Appearance.px(9)
        color: buttonArea.containsMouse
            ? Appearance.layer1Active : Appearance.layer1
        border.width: 1
        border.color: Appearance.outline

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: Appearance.px(5)

            Text {
                text: button.icon
                color: button.destructive
                    ? Theme.palette.m3error : Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(14)
                }
            }

            PanelText {
                visible: button.label.length > 0
                text: button.label
                color: button.destructive
                    ? Theme.palette.m3error : Appearance.layer1Text
                font.pixelSize: Appearance.smallFontSize
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation { duration: Appearance.fastDuration }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(9)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(7)

            Text {
                text: NotificationService.doNotDisturb ? "󰂛" : "󰂚"
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(19)
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: I18n.tr("notifications")
                color: Appearance.layer0Text
                font {
                    pixelSize: Appearance.fontSize + Appearance.px(2)
                    weight: Font.DemiBold
                }
            }

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

            CloseButton {
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.outline
        }

        Flickable {
            id: notificationFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: notificationColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: notificationColumn
                width: notificationFlickable.width
                    - Appearance.px(8)
                spacing: Appearance.px(8)

                RowLayout {
                    Layout.fillWidth: true

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("unreadNotifications")
                            + "  " + NotificationService.unreadCount
                        color: Appearance.layer0Text
                        font.weight: Font.DemiBold
                    }
                }

                PanelText {
                    visible: NotificationService.unreadCount === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(8)
                    Layout.bottomMargin: Appearance.px(8)
                    horizontalAlignment: Text.AlignHCenter
                    text: I18n.tr("noUnreadNotifications")
                    color: Appearance.subtext
                }

                Repeater {
                    model: NotificationService.unreadEntries

                    delegate: NotificationCenterCard {
                        required property var modelData
                        Layout.fillWidth: true
                        notificationEntry: modelData
                        historical: false
                        onActivated: NotificationService.activate(modelData)
                        onSecondaryAction:
                            NotificationService.markRead(
                                modelData.notificationId)
                    }
                }

                Rectangle {
                    visible: NotificationService.historyEntries.length > 0
                        || NotificationService.unreadCount > 0
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(5)
                    implicitHeight: 1
                    color: Appearance.outline
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(2)

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("notificationHistory")
                            + "  "
                            + NotificationService.historyEntries.length
                        color: Appearance.layer0Text
                        font.weight: Font.DemiBold
                    }

                    HeaderButton {
                        visible: NotificationService.historyEntries.length > 0
                        icon: "󰆴"
                        label: I18n.tr("clearHistory")
                        destructive: true
                        onClicked: NotificationService.clearHistory()
                    }
                }

                PanelText {
                    visible: NotificationService.historyEntries.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(8)
                    horizontalAlignment: Text.AlignHCenter
                    text: I18n.tr("noNotificationHistory")
                    color: Appearance.subtext
                }

                Repeater {
                    model: NotificationService.historyEntries

                    delegate: NotificationCenterCard {
                        required property var modelData
                        Layout.fillWidth: true
                        notificationEntry: modelData
                        historical: true
                        onActivated: NotificationService.activate(modelData)
                        onSecondaryAction:
                            NotificationService.removeEntry(
                                modelData.notificationId)
                    }
                }
            }
        }
    }
}
