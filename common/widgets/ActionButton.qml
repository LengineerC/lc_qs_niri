pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    required property string icon
    required property string label
    property bool useBarPalette: false
    property bool selected: false
    property bool primary: false
    property bool destructive: false
    property bool compact: false
    property bool outlined: selected
    property int textWeight: selected ? Font.DemiBold : Font.Normal
    signal clicked

    readonly property bool highlighted: selected || primary

    implicitWidth: buttonRow.implicitWidth
        + (compact ? Appearance.spacingLarge : Appearance.px(20))
    implicitHeight: compact
        ? Appearance.compactControlHeight : Appearance.controlHeight
    radius: compact ? Appearance.fieldRadius : Appearance.controlRadius
    color: highlighted
        ? palette.primaryContainer
        : buttonArea.containsMouse
            ? palette.layer1Active : palette.layer1
    border.width: outlined ? 1 : 0
    border.color: selected ? palette.primary : palette.outline
    opacity: enabled ? 1 : 0.4
    scale: buttonArea.pressed ? 0.96 : 1

    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    RowLayout {
        id: buttonRow
        anchors.centerIn: parent
        spacing: Appearance.px(6)

        AppText {
            visible: root.icon.length > 0
            text: root.icon
            color: root.destructive
                ? palette.error
                : root.highlighted
                    ? palette.primaryContainerText : palette.primary
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.px(root.compact ? 14 : 15)
            }
        }

        AppText {
            visible: root.label.length > 0
            text: root.label
            color: root.destructive
                ? palette.error
                : root.highlighted
                    ? palette.primaryContainerText : palette.layer1Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
                weight: root.textWeight
            }
        }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation { duration: Appearance.fastDuration }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.fastDuration
            easing.type: Easing.OutCubic
        }
    }
}
