pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// Read-only meter: fixed text, animated fill, no input handler or slider thumb.
Item {
    id: root

    property real value: 0
    property string valueText: Math.round(value * 100) + "%"
    property string icon: ""
    property bool useBarPalette: true
    property bool warning: false
    property bool available: true
    property bool animate: visible
    property real displayedValue: available && Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0
    readonly property real boundary: width * displayedValue
    readonly property color fillColor: warning ? palette.error : palette.primary

    implicitHeight: Appearance.compactControlHeight
    implicitWidth: Appearance.px(160)
    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    Behavior on displayedValue {
        enabled: root.animate
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.fieldRadius
        color: palette.layer1Active
    }
    Rectangle {
        width: root.boundary
        height: parent.height
        radius: Math.min(Appearance.fieldRadius, width / 2)
        color: root.fillColor
    }
    component MeterLabel: Item {
        AppText {
            anchors.left: parent.left
            anchors.leftMargin: Appearance.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            text: root.available ? root.valueText : "—"
            color: parent.ink
            font.pixelSize: Appearance.smallFontSize
            font.weight: Font.DemiBold
        }
        AppText {
            anchors.right: parent.right
            anchors.rightMargin: Appearance.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: parent.ink
            font.family: Appearance.iconFontFamily
            font.weight: Font.Normal
            font.pixelSize: Appearance.px(16)
        }
        required property color ink
    }
    MeterLabel {
        anchors.fill: parent
        ink: palette.layer0Text
    }
    // Clip a second text layer to the fill, so contrast remains correct even
    // when the moving boundary passes through a digit.
    Item {
        width: root.boundary
        height: parent.height
        clip: true
        MeterLabel {
            width: root.width
            height: root.height
            ink: root.warning ? palette.onError : SettingsPalette.glassMode ? palette.onPrimary : palette.layer1Active
        }
    }
}
