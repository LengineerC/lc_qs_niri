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
        color: root.containsMouse ? Appearance.layer1Hover : Appearance.layer1
        radius: Appearance.smallRadius
        border.width: 1
        border.color: Appearance.layer0Border

        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }

        Behavior on color {
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
