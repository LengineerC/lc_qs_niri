pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    property bool vertical: false

    signal activated

    implicitWidth: vertical ? Appearance.barHeight : weatherRow.implicitWidth + Appearance.px(18)
    implicitHeight: vertical ? weatherRow.implicitHeight + Appearance.px(12) : Appearance.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: root.containsMouse
            ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: 1
        border.color: Appearance.barOutline
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
        id: weatherRow
        columns: root.vertical ? 1 : -1
        rows: root.vertical ? -1 : 1
        rowSpacing: Appearance.px(2)
        columnSpacing: Appearance.px(5)
        anchors.centerIn: parent

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Appearance.px(20)
            implicitHeight: Appearance.px(20)

            AppText {
                anchors.centerIn: parent
                visible:
                    !(WeatherService.loading && !WeatherService.ready)
                text: WeatherService.currentIcon
                rotation: 0
                color: Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(19)
                }
            }

            AppText {
                id: loadingIcon

                anchors.centerIn: parent
                visible:
                    WeatherService.loading && !WeatherService.ready
                text: "󰔟"
                color: Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(19)
                }

                RotationAnimator {
                    target: loadingIcon
                    running: loadingIcon.visible
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }
        }

        AppText {
            Layout.alignment: Qt.AlignHCenter
            text: WeatherService.currentTemperature
            color: Appearance.barLayer0Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize + 1
                weight: Font.DemiBold
            }
        }
    }
}
