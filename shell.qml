import QtQuick
import Quickshell
import qs.common
import qs.modules.bar
import qs.modules.screenCorners

ShellRoot {
    id: root

    Component.onCompleted: Theme.load()

    ScreenCornersWrapper {
    }

    Bar {
    }

}
