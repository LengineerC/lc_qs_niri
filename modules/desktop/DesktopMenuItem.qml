pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.common

MenuItem {
    id: root
    implicitHeight: Appearance.px(42)
    leftPadding: Appearance.px(12)
    rightPadding: Appearance.px(12)
    contentItem: AppText {
        text: root.text
        color: root.highlighted ? Appearance.primaryContainerText : Appearance.layer0Text
        opacity: root.enabled ? 1 : 0.4
        font.pixelSize: Appearance.px(14)
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: Appearance.px(9)
        color: root.highlighted ? Appearance.primaryContainer : "transparent"
    }
}
