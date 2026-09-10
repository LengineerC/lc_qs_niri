import QtQuick
import qs.common

Rectangle {
    property bool highlighted: false

    radius: Appearance.px(14)
    color: ShellSettings.barFrostedGlass
        ? Appearance.withAlpha(Appearance.barGlassBaseColor, 0.36)
        : Appearance.barLayer1
    border.width: 1
    border.color: Appearance.withAlpha(Appearance.barLayer0Text,
        highlighted ? 0.28 : 0.14)

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: parent.radius
            rightMargin: parent.radius
        }
        height: 1
        color: Appearance.withAlpha(Appearance.barLayer0Text, 0.12)
    }

    Behavior on border.color {
        ColorAnimation { duration: Appearance.fastDuration }
    }
}
