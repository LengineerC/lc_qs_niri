pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    property bool vertical: false

    signal activated

    visible: BatteryService.available
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: vertical ? Appearance.barHeight : batteryRow.implicitWidth + Appearance.px(18)
    implicitHeight: vertical ? batteryRow.implicitHeight + Appearance.px(12) : Appearance.barHeight
    onClicked: activated()

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: root.containsMouse ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: 1
        border.color: Appearance.barLayer0Border
        scale: root.pressed ? 0.94 : 1

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    GridLayout {
        id: batteryRow
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        rowSpacing: Appearance.px(2)
        columnSpacing: Appearance.px(5)

        anchors.centerIn: parent

        AppText {
            Layout.alignment: Qt.AlignHCenter
            text: BatteryService.powerIcon()
            color: BatteryService.low
                ? Appearance.barError
                : BatteryService.pluggedIn
                    ? Appearance.barPrimary : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.fontSize + Appearance.px(4)
            }
        }

        AppText {
            Layout.alignment: Qt.AlignHCenter
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
            Layout.alignment: Qt.AlignHCenter
            visible: BatteryService.showPowerStatus
            implicitWidth: Math.min(Appearance.barHeight - Appearance.px(8), powerStatus.implicitWidth + Appearance.px(12))
            implicitHeight: root.vertical ? powerStatus.implicitHeight + Appearance.px(8) : Appearance.px(22)
            radius: Appearance.fullRadius
            color: Appearance.barPrimaryContainer

            AppText {
            Layout.alignment: Qt.AlignHCenter
                id: powerStatus

                anchors.centerIn: parent
                text: root.vertical ? Array.from(BatteryService.barStatusText).join("\n") : BatteryService.barStatusText
                color: Appearance.barPrimaryContainerText
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }
        }
    }
}
