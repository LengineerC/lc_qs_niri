import QtQuick
import QtQuick.Layouts
import qs.common

MouseArea {
    id: root

    property real padding: Appearance.px(5)
    default property alias items: contentLayout.children

    hoverEnabled: true
    implicitWidth: contentLayout.implicitWidth + padding * 2
    implicitHeight: Appearance.barHeight

    Rectangle {
        color: ShellSettings.barBackgroundless
            ? "transparent"
            : root.containsMouse
                ? Appearance.barLayer1Hover : Appearance.barLayer1
        radius: Appearance.smallRadius
        border.width: ShellSettings.barBackgroundless ? 0 : 1
        border.color: Appearance.barLayer0Border

        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation {
                duration: Appearance.fastDuration
            }

        }

    }

    RowLayout {
        id: contentLayout

        spacing: Appearance.px(4)

        anchors {
            fill: parent
            margins: root.padding
        }

    }

}
