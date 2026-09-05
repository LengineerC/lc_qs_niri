pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    signal activated

    visible: BatteryService.available
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: batteryRow.implicitWidth + Appearance.px(18)
    implicitHeight: Appearance.barHeight
    onClicked: activated()

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: ShellSettings.barBackgroundless
            ? "transparent"
            : root.containsMouse
                ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: ShellSettings.barBackgroundless ? 0 : 1
        border.color: Appearance.barLayer0Border

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }
    }

    RowLayout {
        id: batteryRow

        anchors.centerIn: parent
        spacing: Appearance.px(5)

        Text {
            text: BatteryService.powerIcon()
            color: BatteryService.low
                ? Appearance.barError
                : BatteryService.pluggedIn
                    ? Appearance.barPrimary : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.fontSize + Appearance.px(4)
            }
        }

        Text {
            visible: BatteryService.hasBattery
            text: BatteryService.percent + "%"
            color: BatteryService.low
                ? Appearance.barError : Appearance.barLayer0Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize + 1
            }
        }

        Rectangle {
            visible: BatteryService.showPowerStatus
            implicitWidth: powerStatus.implicitWidth + Appearance.px(12)
            implicitHeight: Appearance.px(22)
            radius: Appearance.fullRadius
            color: ShellSettings.barBackgroundless
                ? "transparent" : Appearance.barPrimaryContainer

            Text {
                id: powerStatus

                anchors.centerIn: parent
                text: BatteryService.barStatusText
                color: ShellSettings.barBackgroundless
                    ? Appearance.barLayer0Text
                    : Appearance.barPrimaryContainerText
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }
        }
    }
}
