pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    property bool compact: false
    property bool vertical: false

    signal activated

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: vertical ? Appearance.barHeight : iconRow.implicitWidth + Appearance.px(20)
    implicitHeight: vertical ? iconRow.implicitHeight + Appearance.px(12) : Appearance.barHeight
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
            ColorAnimation { duration: Appearance.fastDuration }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    GridLayout {
        id: iconRow
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        rowSpacing: Appearance.px(2)

        anchors.centerIn: parent
        columnSpacing: Appearance.px(root.compact ? 8 : 13)

        AppText {
            Layout.alignment: Qt.AlignHCenter
            visible: SystemService.wifiEnabled
            text: SystemService.wifiIcon()
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }

        AppText {
            Layout.alignment: Qt.AlignHCenter
            visible: SystemService.bluetoothEnabled
            text: SystemService.connectedBluetoothDevices.length > 0
                ? "󰂱" : "󰂯"
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }

        AppText {
            Layout.alignment: Qt.AlignHCenter
            visible: SystemService.locationAvailable
                && SystemService.locationEnabled
            text: "󰍎"
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }

        AppText {
            Layout.alignment: Qt.AlignHCenter
            visible: SystemService.sinkReady
            text: SystemService.volumeIcon()
            color: SystemService.muted
                ? Appearance.barSubtext : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }

        AppText {
            Layout.alignment: Qt.AlignHCenter
            visible: SystemService.sourceReady
                && !SystemService.microphoneMuted
            text: SystemService.microphoneIcon()
            color: Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.fontSize + Appearance.px(3)
            }
        }
    }
}
