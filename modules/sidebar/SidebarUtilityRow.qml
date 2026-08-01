pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.px(10)

    FocusTimerCard {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }

    TodoCard {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }
}
