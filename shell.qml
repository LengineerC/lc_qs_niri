import QtQuick
import Quickshell
import qs.common
import qs.modules.bar
import qs.modules.screenCorners
import qs.modules.settings

ShellRoot {
    id: root

    Component.onCompleted: {
        ShellSettings.load();
        SystemService.load();
        Theme.load();
    }

    ScreenCornersWrapper {
    }

    SettingsWindow {
    }

    Bar {
    }

}
