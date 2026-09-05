pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    property bool compact: false
    signal activated

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: iconRow.implicitWidth + Appearance.px(20)
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
            ColorAnimation { duration: Appearance.fastDuration }
        }
    }

    RowLayout {
        id: iconRow

        anchors.centerIn: parent
        spacing: Appearance.px(root.compact ? 8 : 13)

        Text {
            visible: SystemService.wifiEnabled
            text: SystemService.wifiIcon()
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }

        Text {
            visible: SystemService.bluetoothEnabled
            text: SystemService.connectedBluetoothDevices.length > 0
                ? "󰂱" : "󰂯"
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }

        Text {
            visible: SystemService.sinkReady
            text: SystemService.volumeIcon()
            color: SystemService.muted
                ? Appearance.barSubtext : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }
    }
}
