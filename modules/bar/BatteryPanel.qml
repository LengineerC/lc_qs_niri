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
        color: Appearance.barLayer1Text
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
            ? Appearance.barPrimaryContainer
            : profileMouse.containsMouse
                ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: 1
        border.color: active ? Appearance.barPrimary : Appearance.barOutline

        Column {
            anchors.centerIn: parent
            spacing: Appearance.px(2)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: profileButton.icon
                color: profileButton.active
                    ? Appearance.barPrimaryContainerText : Appearance.barLayer1Text
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(20)
                }
            }

            PanelText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: profileButton.label
                color: profileButton.active
                    ? Appearance.barPrimaryContainerText : Appearance.barLayer1Text
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
            useBarPalette: true
            icon: BatteryService.powerIcon()
            iconColor: BatteryService.low
                ? Appearance.barError : Appearance.barPrimary
            iconSize: Appearance.px(23)
            title: BatteryService.panelTitle
            // onCloseClicked: root.closeRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(92)
            radius: Appearance.smallRadius
            color: Appearance.barLayer1
            border.width: 1
            border.color: Appearance.barOutline

            Item {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(33)
                    rightMargin: Appearance.px(33)
                }

                Text {
                    id: mainBatteryIcon

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: BatteryService.powerIcon()
                    color: BatteryService.low
                        ? Appearance.barError : Appearance.barPrimary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(42)
                    }
                }

                PanelText {
                    id: profileLabel

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: BatteryService.profileName
                    color: Appearance.barPrimary
                    font.weight: Font.DemiBold
                }

                Column {
                    anchors {
                        left: mainBatteryIcon.right
                        right: profileLabel.left
                        leftMargin: Appearance.px(18)
                        rightMargin: Appearance.px(18)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 0

                    PanelText {
                        width: parent.width
                        text: BatteryService.hasBattery
                            ? BatteryService.percent + "%"
                            : I18n.tr("externalPower")
                        color: BatteryService.low
                            ? Appearance.barError : Appearance.barLayer0Text
                        font {
                            pixelSize: Appearance.px(26)
                            weight: Font.Bold
                        }
                        elide: Text.ElideRight
                    }

                    PanelText {
                        width: parent.width
                        text: {
                            const remaining = BatteryService.formatTime();
                            if (!remaining)
                                return BatteryService.statusText;
                            return BatteryService.statusText + " · "
                                + remaining;
                        }
                        color: Appearance.barSubtext
                        font.pixelSize: Appearance.smallFontSize
                        elide: Text.ElideRight
                    }

                    PanelText {
                        visible: !BatteryService.hasBattery
                        width: parent.width
                        text: I18n.tr("noBatteryDetected")
                        color: Appearance.barSubtext
                        font.pixelSize: Appearance.smallFontSize
                        elide: Text.ElideRight
                    }
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
                color: Appearance.barLayer3

                Column {
                    anchors.centerIn: parent
                    spacing: Appearance.px(3)

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.tr("batteryCapacity")
                        color: Appearance.barSubtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: BatteryService.capacityWh > 0
                            ? BatteryService.capacityWh.toFixed(1) + " Wh"
                            : I18n.tr("unknown")
                        color: Appearance.barLayer0Text
                        font.weight: Font.Bold
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(68)
                radius: Appearance.smallRadius
                color: Appearance.barLayer3

                Column {
                    anchors.centerIn: parent
                    spacing: Appearance.px(3)

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.tr("batteryHealth")
                        color: Appearance.barSubtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    PanelText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: BatteryService.healthAvailable
                            ? Math.round(BatteryService.health) + "%"
                            : I18n.tr("unknown")
                        color: BatteryService.healthAvailable
                                && BatteryService.health < 80
                            ? Appearance.barError : Appearance.barLayer0Text
                        font.weight: Font.Bold
                    }
                }
            }
        }

        PanelText {
            Layout.fillWidth: true
            text: I18n.tr("powerProfile")
            color: Appearance.barLayer0Text
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
            color: Appearance.barError
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.smallFontSize
        }
    }
}
