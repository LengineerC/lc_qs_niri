pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    default property alias content: contentLayout.children

    property bool useBarPalette: false
    property real padding: Appearance.spacingMedium
    property real contentSpacing: Appearance.spacingSmall
    property color surfaceColor: palette.layer3
    property color outlineColor: palette.outline
    signal backgroundClicked

    Layout.fillWidth: true
    implicitHeight: contentLayout.implicitHeight + padding * 2
    radius: Appearance.cardRadius
    color: surfaceColor
    border.width: 1
    border.color: outlineColor

    BarPalette {
        id: palette
        enabled: root.useBarPalette
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.backgroundClicked()
    }

    ColumnLayout {
        id: contentLayout

        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.contentSpacing
    }
}
