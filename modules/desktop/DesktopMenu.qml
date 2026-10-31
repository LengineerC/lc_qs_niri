pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.common

Menu {
    id: root
    padding: Appearance.px(6)
    implicitWidth: Appearance.px(300)
    popupType: Popup.Item
    background: Rectangle {
        color: Appearance.layer2
        radius: Appearance.px(14)
        border.color: Appearance.outline
        border.width: 1
    }
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90 }
    }
}
