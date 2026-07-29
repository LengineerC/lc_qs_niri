import QtQuick
import Quickshell
import qs.common
import qs.modules.bar
import qs.modules.ScreenCorners
import qs.modules.settings
import qs.services

ShellRoot {
    id: root

    Component.onCompleted: {
        ShellSettings.load();
        ClipboardService.load();
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
