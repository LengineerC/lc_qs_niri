//@ pragma UseQApplication

import QtQuick
import Quickshell
import qs.common
import qs.modules.bar
import qs.modules.ScreenCorners
import qs.modules.notifications
import qs.modules.settings
import qs.modules.wallpaper
import qs.modules.lock
import qs.services

ShellRoot {
    id: root

    Component.onCompleted: {
        ShellSettings.load();
        ClipboardService.load();
        NotificationService.load();
        WallpaperService.load();
        SystemService.load();
        ResourceService.load();
        OutputService.load();
        BrightnessService.load();
        UserService.load();
        LockService.load();
        WeatherService.load();
        Theme.load();
        LeftSidebarService.load();
    }

    ScreenCornersWrapper {
    }

    WallpaperBackground {
    }

    SettingsWindow {
    }

    NotificationToasts {
    }

    Lock {
    }

    UtilityWindows {
    }

    Bar {
    }

}
