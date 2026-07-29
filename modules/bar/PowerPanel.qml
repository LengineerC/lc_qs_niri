pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    implicitWidth: Appearance.px(410)
    implicitHeight: contentColumn.implicitHeight + Appearance.px(28)

    function perform(action) {
        closeRequested();
        Qt.callLater(() => {
            switch (action) {
            case "poweroff":
                UserService.powerOff();
                break;
            case "reboot":
                UserService.reboot();
                break;
            case "logout":
                UserService.logout();
                break;
            case "suspend":
                UserService.suspend();
                break;
            }
        });
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component PowerAction: Rectangle {
        id: actionButton

        required property string action
        required property string icon
        required property string label
        property bool destructive: false

        Layout.fillWidth: true
        implicitHeight: Appearance.px(54)
        radius: Appearance.smallRadius
        color: actionArea.containsMouse
            ? destructive
                ? Appearance.withAlpha(
                    Theme.palette.m3error, 0.14)
                : Appearance.layer1Hover
            : Appearance.layer1
        border.width: 1
        border.color: actionArea.containsMouse && destructive
            ? Theme.palette.m3error : Appearance.outline
        scale: actionArea.pressed ? 0.985 : 1

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(15)
                rightMargin: Appearance.px(15)
            }
            spacing: Appearance.px(12)

            Rectangle {
                implicitWidth: Appearance.px(34)
                implicitHeight: Appearance.px(34)
                radius: Appearance.px(10)
                color: actionButton.destructive
                    ? Appearance.withAlpha(
                        Theme.palette.m3error, 0.14)
                    : Appearance.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: actionButton.icon
                    color: actionButton.destructive
                        ? Theme.palette.m3error
                        : Appearance.primaryContainerText
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(17)
                    }
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: actionButton.label
                color: actionButton.destructive
                    ? Theme.palette.m3error : Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            Text {
                text: "󰅂"
                color: Appearance.subtext
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(15)
                }
            }
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.perform(actionButton.action)
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
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(9)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            Text {
                text: "󰐥"
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(21)
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: I18n.tr("powerMenu")
                color: Appearance.layer0Text
                font {
                    pixelSize: Appearance.largeFontSize
                    weight: Font.DemiBold
                }
            }

            CloseButton {
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(104)
            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(14)
                }
                spacing: Appearance.px(14)

                UserAvatar {
                    implicitSize: Appearance.px(72)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.px(3)

                    PanelText {
                        Layout.fillWidth: true
                        text: UserService.displayName
                        color: Appearance.layer0Text
                        elide: Text.ElideRight
                        font {
                            pixelSize: Appearance.largeFontSize
                            weight: Font.DemiBold
                        }
                    }

                    PanelText {
                        visible: UserService.loginName
                            && UserService.loginName
                                !== UserService.displayName
                        text: "@" + UserService.loginName
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    RowLayout {
                        spacing: Appearance.px(6)

                        Text {
                            text: "󰥔"
                            color: Appearance.primary
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(14)
                            }
                        }

                        PanelText {
                            text: I18n.tr("systemUptime") + " · "
                                + UserService.formatUptime()
                            color: Appearance.subtext
                            font.pixelSize: Appearance.smallFontSize
                        }
                    }
                }
            }
        }

        PowerAction {
            action: "poweroff"
            icon: "󰐥"
            label: I18n.tr("shutDown")
            destructive: true
        }

        PowerAction {
            action: "reboot"
            icon: "󰜉"
            label: I18n.tr("restart")
        }

        PowerAction {
            action: "logout"
            icon: "󰍃"
            label: I18n.tr("logOut")
        }

        PowerAction {
            action: "suspend"
            icon: "󰤄"
            label: I18n.tr("suspend")
        }
    }
}
