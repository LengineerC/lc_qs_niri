pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: root

    readonly property var privateEntries:
        NotificationService.unreadEntries.slice(0, 4)
    readonly property int unreadCount:
        NotificationService.unreadCount

    color: Appearance.barLayer2
    radius: Appearance.normalRadius
    border.width: 1
    border.color: Appearance.barOutline
    clip: true

    function formatTime(timestamp) {
        const date = new Date(Number(timestamp));
        if (Number.isNaN(date.getTime()))
            return "";
        const now = new Date();
        if (date.toDateString() === now.toDateString())
            return I18n.locale.toString(date, "HH:mm");
        return I18n.locale.toString(date, "MM/dd");
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(16)
        }
        spacing: Appearance.px(9)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            AppText {
                text: "󰂚"
                color: Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(18)
                }
            }

            AppText {
                Layout.fillWidth: true
                text: root.unreadCount > 0
                    ? I18n.tr("newNotificationCount")
                        .arg(root.unreadCount)
                    : I18n.tr("notifications")
                color: Appearance.barLayer0Text
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.largeFontSize
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                implicitWidth: privacyRow.implicitWidth
                    + Appearance.px(14)
                implicitHeight: Appearance.px(28)
                radius: Appearance.fullRadius
                color: Appearance.barPrimaryContainer

                RowLayout {
                    id: privacyRow
                    anchors.centerIn: parent
                    spacing: Appearance.px(5)

                    AppText {
                        text: "󰌾"
                        color: Appearance.barPrimaryContainerText
                        font {
                            family: Appearance.iconFontFamily
                            weight: Font.Normal
                            pixelSize: Appearance.px(12)
                        }
                    }

                    AppText {
                        text: I18n.tr("private")
                        color: Appearance.barPrimaryContainerText
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                            weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        AppText {
            Layout.fillWidth: true
            text: I18n.tr("notificationContentHidden")
            color: Appearance.barSubtext
            wrapMode: Text.Wrap
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.privateEntries.length === 0
                spacing: Appearance.px(8)

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂛"
                    color: Appearance.barSubtext
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
                        pixelSize: Appearance.px(42)
                    }
                }

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("noUnreadNotifications")
                    color: Appearance.barSubtext
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.fontSize
                    }
                }
            }

            ListView {
                anchors.fill: parent
                visible: root.privateEntries.length > 0
                interactive: false
                spacing: Appearance.px(7)
                model: root.privateEntries

                delegate: Rectangle {
                    id: notificationDelegate

                    required property var modelData

                    width: ListView.view.width
                    height: Appearance.px(58)
                    radius: Appearance.smallRadius
                    color: Appearance.barLayer3
                    border.width: 1
                    border.color: Appearance.barOutline

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: Appearance.px(10)
                        }
                        spacing: Appearance.px(10)

                        Rectangle {
                            implicitWidth: Appearance.px(36)
                            implicitHeight: Appearance.px(36)
                            radius: Appearance.px(10)
                            color: Appearance.barPrimaryContainer

                            AppText {
                                anchors.centerIn: parent
                                text: "󰌾"
                                color: Appearance.barPrimaryContainerText
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(16)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            AppText {
                                Layout.fillWidth: true
                                text: notificationDelegate.modelData
                                    ?.appName
                                    || I18n.tr("unknownApplication")
                                color: Appearance.barLayer0Text
                                elide: Text.ElideRight
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }

                            AppText {
                                text: I18n.tr("newNotification")
                                color: Appearance.barSubtext
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.smallFontSize
                                }
                            }
                        }

                        AppText {
                            text: root.formatTime(
                                notificationDelegate.modelData
                                    ?.timestamp)
                            color: Appearance.barSubtext
                            font {
                                family: Appearance.fontFamily
                                pixelSize: Appearance.smallFontSize
                            }
                        }
                    }
                }
            }
        }
    }
}
