pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import qs.common

Controls.Slider {
    id: root

    property bool useBarPalette: false
    property string valueText: ""
    property string iconText: ""
    property color iconColor: palette.layer1Text
    signal iconActivated

    implicitHeight: Appearance.largeControlHeight
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    background: Item {
        id: sliderTrack

        readonly property real handleCenter:
            root.visualPosition * (width - sliderHandle.width)
                + sliderHandle.width / 2
        readonly property real handleGap: Appearance.px(5)

        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: Appearance.compactControlHeight

        Rectangle {
            width: Math.max(0,
                sliderTrack.handleCenter - sliderTrack.handleGap)
            height: parent.height
            radius: Math.min(Appearance.fieldRadius, width / 2)
            topRightRadius: Math.min(Appearance.detailRadius, width / 2)
            bottomRightRadius: topRightRadius
            color: root.enabled ? palette.primary : palette.layer1Active
        }

        Rectangle {
            x: Math.min(parent.width,
                sliderTrack.handleCenter + sliderTrack.handleGap)
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: Math.min(Appearance.fieldRadius, width / 2)
            topLeftRadius: Math.min(Appearance.detailRadius, width / 2)
            bottomLeftRadius: topLeftRadius
            color: palette.layer1Active
            border.width: 1
            border.color: Appearance.withAlpha(palette.outline, 0.5)
        }

        AppText {
            anchors {
                left: parent.left
                leftMargin: Appearance.controlRadius
                verticalCenter: parent.verticalCenter
            }
            text: root.valueText
            color: root.enabled && root.visualPosition >= 0.1
                ? SettingsPalette.glassMode ? palette.onPrimary : palette.layer1Active 
                : palette.layer1Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }

        Item {
            anchors {
                right: parent.right
                rightMargin: Appearance.px(5)
                verticalCenter: parent.verticalCenter
            }
            width: Appearance.iconButtonSize
            height: parent.height

            AppText {
                anchors.centerIn: parent
                text: root.iconText
                color: root.enabled && root.visualPosition >= 0.95
                    ? SettingsPalette.glassMode ? palette.onPrimary : palette.layer1Active 
                    : root.iconColor
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(16)
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                cursorShape: enabled
                    ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.iconActivated()
            }
        }

        Rectangle {
            anchors {
                right: parent.right
                rightMargin: Appearance.px(3)
                verticalCenter: parent.verticalCenter
            }
            width: Appearance.px(3)
            height: width
            radius: width / 2
            color: root.enabled && root.visualPosition >= 0.99
                ? palette.onPrimary : palette.subtext
        }
    }

    handle: Rectangle {
        id: sliderHandle

        x: root.leftPadding + root.visualPosition
            * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: Appearance.px(3)
        implicitHeight: root.height
        radius: Appearance.fullRadius
        color: root.enabled ? palette.primary : palette.subtext
    }
}
