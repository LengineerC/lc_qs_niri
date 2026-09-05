pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    signal activated

    implicitWidth: weatherRow.implicitWidth + Appearance.px(18)
    implicitHeight: Appearance.barHeight
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
        color: ShellSettings.barBackgroundless
            ? "transparent"
            : root.containsMouse
            ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: ShellSettings.barBackgroundless ? 0 : 1
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

    RowLayout {
        id: weatherRow
        anchors.centerIn: parent
        spacing: Appearance.px(5)

        Item {
            implicitWidth: Appearance.px(20)
            implicitHeight: Appearance.px(20)

            Text {
                anchors.centerIn: parent
                visible:
                    !(WeatherService.loading && !WeatherService.ready)
                text: WeatherService.currentIcon
                rotation: 0
                color: Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(19)
                }
            }

            Text {
                id: loadingIcon

                anchors.centerIn: parent
                visible:
                    WeatherService.loading && !WeatherService.ready
                text: "󰔟"
                color: Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
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

        Text {
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
