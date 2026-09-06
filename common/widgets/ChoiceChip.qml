pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    required property string label
    required property bool selected
    property bool useBarPalette: false
    property int textWeight: selected ? Font.DemiBold : Font.Normal
    signal chosen

    Layout.fillWidth: true
    implicitHeight: Appearance.controlHeight
    radius: Appearance.fieldRadius
    color: selected
        ? palette.primaryContainer
        : choiceMouse.containsMouse
            ? palette.layer1Active : palette.layer1
    border.width: 1
    border.color: selected ? palette.primary : palette.outline
    scale: choiceMouse.pressed ? 0.97 : 1

    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    AppText {
        anchors {
            fill: parent
            leftMargin: Appearance.spacingSmall
            rightMargin: Appearance.spacingSmall
        }
        text: root.label
        color: root.selected
            ? palette.primaryContainerText : palette.layer1Text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.smallFontSize
            weight: root.textWeight
        }
    }

    MouseArea {
        id: choiceMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.chosen()
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
