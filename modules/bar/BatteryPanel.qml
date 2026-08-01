pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    implicitWidth: Appearance.px(420)
    implicitHeight: contentColumn.implicitHeight + Appearance.px(28)

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component ProfileButton: Rectangle {
        id: profileButton

        required property int profile
        required property string label
        required property string icon
        property bool active: BatteryService.profile === profile

        Layout.fillWidth: true
        implicitHeight: Appearance.px(62)
        radius: Appearance.smallRadius
        color: active
            ? Appearance.primaryContainer
            : profileMouse.containsMouse
                ? Appearance.layer1Hover : Appearance.layer1
        border.width: 1
        border.color: active ? Appearance.primary : Appearance.outline

        Column {
            anchors.centerIn: parent
            spacing: Appearance.px(2)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: profileButton.icon
                color: profileButton.active
                    ? Appearance.primaryContainerText : Appearance.layer1Text
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(20)
                }
            }

            PanelText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: profileButton.label
                color: profileButton.active
                    ? Appearance.primaryContainerText : Appearance.layer1Text
                font.pixelSize: Appearance.smallFontSize
            }
        }

        MouseArea {
            id: profileMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: BatteryService.setProfile(profileButton.profile)
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.fastDuration
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
        spacing: Appearance.px(10)

        PopupHeader {
            icon: BatteryService.powerIcon()
            iconColor: BatteryService.low
                ? Theme.palette.m3error : Appearance.primary
            iconSize: Appearance.px(23)
            title: BatteryService.panelTitle
            // onCloseClicked: root.closeRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(92)
            radius: Appearance.smallRadius
            color: Appearance.layer1
            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(14)
                }
                spacing: Appearance.px(14)

                Text {
                    text: BatteryService.powerIcon()
                    color: BatteryService.low
                        ? Theme.palette.m3error : Appearance.primary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(42)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PanelText {
                        text: BatteryService.hasBattery
                            ? BatteryService.percent + "%"
                            : I18n.tr("externalPower")
                        color: BatteryService.low
                            ? Theme.palette.m3error : Appearance.layer0Text
                        font {
                            pixelSize: Appearance.px(26)
                            weight: Font.Bold
                        }
                    }

                    PanelText {
                        text: {
                            const remaining = BatteryService.formatTime();
                            if (!remaining)
                                return BatteryService.statusText;
                            return BatteryService.statusText + " · "
                                + remaining;
                        }
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    PanelText {
                        visible: !BatteryService.hasBattery
                        text: I18n.tr("noBatteryDetected")
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }
                }

                PanelText {
                    text: BatteryService.profileName
                    color: Appearance.primary
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            visible: BatteryService.hasBattery
            Layout.fillWidth: true
            spacing: Appearance.px(9)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(68)
                radius: Appearance.smallRadius
                color: Appearance.layer3

                Column {
                    anchors.centerIn: parent
                    spacing: Appearance.px(3)

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.tr("batteryCapacity")
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: BatteryService.capacityWh > 0
                            ? BatteryService.capacityWh.toFixed(1) + " Wh"
                            : I18n.tr("unknown")
                        color: Appearance.layer0Text
                        font.weight: Font.Bold
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(68)
                radius: Appearance.smallRadius
                color: Appearance.layer3

                Column {
                    anchors.centerIn: parent
                    spacing: Appearance.px(3)

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.tr("batteryHealth")
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: BatteryService.healthAvailable
                            ? Math.round(BatteryService.health) + "%"
                            : I18n.tr("unknown")
                        color: BatteryService.healthAvailable
                                && BatteryService.health < 80
                            ? Theme.palette.m3error : Appearance.layer0Text
                        font.weight: Font.Bold
                    }
                }
            }
        }

        PanelText {
            Layout.fillWidth: true
            text: I18n.tr("powerProfile")
            color: Appearance.layer0Text
            font.weight: Font.DemiBold
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            ProfileButton {
                profile: PowerProfile.PowerSaver
                label: I18n.tr("powerSaver")
                icon: BatteryService.profileIcon(profile)
            }

            ProfileButton {
                profile: PowerProfile.Balanced
                label: I18n.tr("balanced")
                icon: BatteryService.profileIcon(profile)
            }

            ProfileButton {
                visible: BatteryService.hasPerformanceProfile
                profile: PowerProfile.Performance
                label: I18n.tr("performance")
                icon: BatteryService.profileIcon(profile)
            }
        }

        PanelText {
            visible: BatteryService.degradationReason
                !== PerformanceDegradationReason.None
            Layout.fillWidth: true
            text: I18n.tr("performanceLimited")
                + PerformanceDegradationReason.toString(
                    BatteryService.degradationReason)
            color: Theme.palette.m3error
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.smallFontSize
        }
    }
}
