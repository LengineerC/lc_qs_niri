pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

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
        color: root.containsMouse ? Appearance.layer1Hover : Appearance.layer1
        border.width: 1
        border.color: Appearance.layer0Border

        Behavior on color {
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
            text: BatteryService.batteryIcon()
            color: BatteryService.low
                ? Theme.palette.m3error
                : BatteryService.charging
                    ? Appearance.primary : Appearance.layer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.fontSize + Appearance.px(4)
            }
        }

        Text {
            text: BatteryService.percent + "%"
            color: BatteryService.low
                ? Theme.palette.m3error : Appearance.layer0Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }
    }
}
