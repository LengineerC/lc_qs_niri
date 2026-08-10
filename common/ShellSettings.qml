pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool showActiveWindowIcon: true
    property bool showEmptyWorkspaces: true
    property bool shadowEnabled: true
    property int shadowBlurRadius: 18
    property real shadowOpacity: 0.45
    property int shadowOffsetY: 4
    property string screenCornerColor: "#000000"
    property int animationDuration: 500
    property real popupBezierX1: 0.38
    property real popupBezierY1: 1.21
    property real popupBezierX2: 0.22
    property real popupBezierY2: 1.00
    property string barFontFamily: "JetBrainsMono Nerd Font"
    property string monospaceFontFamily: "monospace"
    property int barFontSize: 13
    property real scale: 1.00
    property string language: "zh_CN"
    property string timeFormat: "HH:mm"
    property string dateFormat: "MMM dd ddd"
    // "group" centers the complete middle row; "clock" pins the clock's
    // midpoint to the Bar midpoint.
    property string barCenterAlignment: "group"
    // -1 follows the active locale; 0/1/6 use JS weekday numbering.
    property int calendarWeekStart: -1
    property int clipboardMaxEntryMb: 10
    property int clipboardMaxEntries: 100
    property bool doNotDisturb: false
    property string wallpaperDirectory: ""
    property bool wallpaperAutoTheme: true
    property string wallpaperFillMode: "PreserveAspectCrop"
    property string wallpaperTransition: "random"
    property bool showCpuUsage: true
    property bool showMemoryUsage: true
    property bool showCpuTemperature: false
    property string userAvatarPath: ""
    property string weatherLocationName: "上海"
    property real weatherLatitude: 31.2304
    property real weatherLongitude: 121.4737
    property var sidebarModuleOrder: defaultSidebarModuleOrder()

    property bool ready: false
    property bool storageReady: false
    property bool applyingState: false

    readonly property string stateDirectory: stripFileProtocol(
        StandardPaths.standardLocations(StandardPaths.StateLocation)[0])
        + "/lc_qs_niri"
    readonly property string settingsFilePath: stateDirectory + "/settings.json"
    readonly property string sidebarTasksFilePath:
        stateDirectory + "/sidebar-tasks.json"
    readonly property var popupBezierCurve: [
        popupBezierX1, popupBezierY1,
        popupBezierX2, popupBezierY2,
        1, 1
    ]

    function stripFileProtocol(path) {
        return String(path).replace(/^file:\/\//, "");
    }

    function clamped(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, Number(value)));
    }

    function defaultSidebarModuleOrder() {
        return [
            "fastfetch",
            "focusTimer",
            "todo",
            "quickNote",
            "dayProgress"
        ];
    }

    function sanitizedSidebarModuleOrder(value) {
        const validModules = defaultSidebarModuleOrder();
        const result = [];

        if (Array.isArray(value)) {
            for (const entry of value) {
                const moduleKey = String(entry);
                if (validModules.indexOf(moduleKey) >= 0
                        && result.indexOf(moduleKey) < 0) {
                    result.push(moduleKey);
                }
            }
        }

        for (const moduleKey of validModules) {
            if (result.indexOf(moduleKey) < 0)
                result.push(moduleKey);
        }
        return result;
    }

    function scheduleSave() {
        if (ready && storageReady && !applyingState)
            saveTimer.restart();
    }

    function save() {
        if (!storageReady || applyingState)
            return;

        settingsStorage.setText(JSON.stringify({
            version: 19,
            showActiveWindowIcon: showActiveWindowIcon,
            showEmptyWorkspaces: showEmptyWorkspaces,
            shadowEnabled: shadowEnabled,
            shadowBlurRadius: shadowBlurRadius,
            shadowOpacity: shadowOpacity,
            shadowOffsetY: shadowOffsetY,
            screenCornerColor: screenCornerColor,
            animationDuration: animationDuration,
            popupBezier: [
                popupBezierX1, popupBezierY1,
                popupBezierX2, popupBezierY2
            ],
            barFontFamily: barFontFamily,
            monospaceFontFamily: monospaceFontFamily,
            barFontSize: barFontSize,
            scale: scale,
            language: language,
            timeFormat: timeFormat,
            dateFormat: dateFormat,
            barCenterAlignment: barCenterAlignment,
            calendarWeekStart: calendarWeekStart,
            clipboardMaxEntryMb: clipboardMaxEntryMb,
            clipboardMaxEntries: clipboardMaxEntries,
            doNotDisturb: doNotDisturb,
            wallpaperDirectory: wallpaperDirectory,
            wallpaperAutoTheme: wallpaperAutoTheme,
            wallpaperFillMode: wallpaperFillMode,
            wallpaperTransition: wallpaperTransition,
            showCpuUsage: showCpuUsage,
            showMemoryUsage: showMemoryUsage,
            showCpuTemperature: showCpuTemperature,
            userAvatarPath: userAvatarPath,
            weatherLocationName: weatherLocationName,
            weatherLatitude: weatherLatitude,
            weatherLongitude: weatherLongitude,
            sidebarModuleOrder: sidebarModuleOrder
        }, null, 2));
    }

    function applySavedSettings(data) {
        applyingState = true;
        let needsMigration = false;
        try {
            const state = JSON.parse(data);
            if (state.version !== 19)
                needsMigration = true;
            if (typeof state.showActiveWindowIcon === "boolean")
                showActiveWindowIcon = state.showActiveWindowIcon;
            if (typeof state.showEmptyWorkspaces === "boolean")
                showEmptyWorkspaces = state.showEmptyWorkspaces;
            else
                needsMigration = true;
            if (typeof state.shadowEnabled === "boolean")
                shadowEnabled = state.shadowEnabled;
            else
                needsMigration = true;
            if (state.shadowBlurRadius !== undefined)
                shadowBlurRadius = Math.round(clamped(
                    state.shadowBlurRadius, 0, 48));
            else
                needsMigration = true;
            if (state.shadowOpacity !== undefined)
                shadowOpacity = clamped(state.shadowOpacity, 0, 0.9);
            else
                needsMigration = true;
            if (state.shadowOffsetY !== undefined)
                shadowOffsetY = Math.round(clamped(
                    state.shadowOffsetY, -12, 24));
            else
                needsMigration = true;
            if (typeof state.screenCornerColor === "string"
                    && /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(
                        state.screenCornerColor)) {
                screenCornerColor = state.screenCornerColor;
            } else {
                needsMigration = true;
            }
            if (state.animationDuration !== undefined)
                animationDuration = Math.round(clamped(
                    state.animationDuration, 100, 1200));

            if (Array.isArray(state.popupBezier)
                    && state.popupBezier.length >= 4) {
                popupBezierX1 = clamped(state.popupBezier[0], 0, 1);
                popupBezierY1 = clamped(state.popupBezier[1], -0.5, 2);
                popupBezierX2 = clamped(state.popupBezier[2], 0, 1);
                popupBezierY2 = clamped(state.popupBezier[3], -0.5, 2);
            }

            if (typeof state.barFontFamily === "string"
                    && state.barFontFamily.trim())
                barFontFamily = state.barFontFamily.trim();
            if (typeof state.monospaceFontFamily === "string"
                    && state.monospaceFontFamily.trim())
                monospaceFontFamily = state.monospaceFontFamily.trim();
            else
                needsMigration = true;
            if (state.barFontSize !== undefined)
                barFontSize = Math.round(clamped(state.barFontSize, 9, 24));
            if (state.scale !== undefined)
                scale = clamped(state.scale, 0.75, 1.5);
            if (state.language === "zh_CN" || state.language === "en_US")
                language = state.language;
            else
                needsMigration = true;
            if (typeof state.timeFormat === "string"
                    && state.timeFormat.trim())
                timeFormat = state.timeFormat.trim().slice(0, 64);
            else
                needsMigration = true;
            if (typeof state.dateFormat === "string"
                    && state.dateFormat.trim())
                dateFormat = state.dateFormat.trim().slice(0, 64);
            else
                needsMigration = true;
            if (["group", "clock"].indexOf(
                    state.barCenterAlignment) >= 0) {
                barCenterAlignment = state.barCenterAlignment;
            } else {
                needsMigration = true;
            }
            if ([-1, 0, 1, 6].indexOf(
                    Number(state.calendarWeekStart)) >= 0) {
                calendarWeekStart = Number(state.calendarWeekStart);
            } else {
                needsMigration = true;
            }
            if (state.clipboardMaxEntryMb !== undefined)
                clipboardMaxEntryMb = Math.round(clamped(
                    state.clipboardMaxEntryMb, 1, 100));
            else
                needsMigration = true;
            if (state.clipboardMaxEntries !== undefined)
                clipboardMaxEntries = Math.round(clamped(
                    state.clipboardMaxEntries, 10, 500));
            else
                needsMigration = true;
            if (typeof state.doNotDisturb === "boolean")
                doNotDisturb = state.doNotDisturb;
            else
                needsMigration = true;
            if (typeof state.wallpaperDirectory === "string")
                wallpaperDirectory = state.wallpaperDirectory;
            else
                needsMigration = true;
            if (typeof state.wallpaperAutoTheme === "boolean")
                wallpaperAutoTheme = state.wallpaperAutoTheme;
            else
                needsMigration = true;
            if (typeof state.wallpaperFillMode === "string"
                    && [
                        "Stretch",
                        "PreserveAspectFit",
                        "PreserveAspectCrop",
                        "Tile",
                        "TileVertically",
                        "TileHorizontally",
                        "Pad"
                    ].indexOf(state.wallpaperFillMode) >= 0)
                wallpaperFillMode = state.wallpaperFillMode;
            else
                needsMigration = true;
            if (typeof state.wallpaperTransition === "string"
                    && [
                        "none", "fade", "wipe", "disc", "stripes",
                        "iris", "pixelate", "portal", "random"
                    ].indexOf(state.wallpaperTransition) >= 0)
                wallpaperTransition = state.wallpaperTransition;
            else
                needsMigration = true;
            if (typeof state.showCpuUsage === "boolean")
                showCpuUsage = state.showCpuUsage;
            else
                needsMigration = true;
            if (typeof state.showMemoryUsage === "boolean")
                showMemoryUsage = state.showMemoryUsage;
            else
                needsMigration = true;
            if (typeof state.showCpuTemperature === "boolean")
                showCpuTemperature = state.showCpuTemperature;
            else
                needsMigration = true;
            if (typeof state.userAvatarPath === "string")
                userAvatarPath = stripFileProtocol(state.userAvatarPath);
            else
                needsMigration = true;
            if (typeof state.weatherLocationName === "string"
                    && state.weatherLocationName.trim())
                weatherLocationName =
                    state.weatherLocationName.trim().slice(0, 120);
            else
                needsMigration = true;
            if (Number.isFinite(Number(state.weatherLatitude)))
                weatherLatitude = clamped(
                    state.weatherLatitude, -90, 90);
            else
                needsMigration = true;
            if (Number.isFinite(Number(state.weatherLongitude)))
                weatherLongitude = clamped(
                    state.weatherLongitude, -180, 180);
            else
                needsMigration = true;
            if (Array.isArray(state.sidebarModuleOrder)) {
                const sanitizedOrder = sanitizedSidebarModuleOrder(
                    state.sidebarModuleOrder);
                sidebarModuleOrder = sanitizedOrder;
                if (JSON.stringify(state.sidebarModuleOrder)
                        !== JSON.stringify(sanitizedOrder)) {
                    needsMigration = true;
                }
            } else {
                needsMigration = true;
            }
        } catch (error) {
            console.warn("ShellSettings: cannot parse settings:", error);
        }
        applyingState = false;
        ready = true;
        if (needsMigration)
            Qt.callLater(() => root.save());
    }

    function resetDefaults() {
        showActiveWindowIcon = true;
        showEmptyWorkspaces = true;
        shadowEnabled = true;
        shadowBlurRadius = 18;
        shadowOpacity = 0.45;
        shadowOffsetY = 4;
        screenCornerColor = "#000000";
        animationDuration = 500;
        popupBezierX1 = 0.38;
        popupBezierY1 = 1.21;
        popupBezierX2 = 0.22;
        popupBezierY2 = 1.00;
        barFontFamily = "JetBrainsMono Nerd Font";
        monospaceFontFamily = "monospace";
        barFontSize = 13;
        scale = 1.00;
        language = "zh_CN";
        timeFormat = "HH:mm";
        dateFormat = "MMM dd ddd";
        barCenterAlignment = "group";
        calendarWeekStart = -1;
        clipboardMaxEntryMb = 10;
        clipboardMaxEntries = 100;
        doNotDisturb = false;
        wallpaperDirectory = "";
        wallpaperAutoTheme = true;
        wallpaperFillMode = "PreserveAspectCrop";
        wallpaperTransition = "random";
        showCpuUsage = true;
        showMemoryUsage = true;
        showCpuTemperature = false;
        userAvatarPath = "";
        weatherLocationName = "上海";
        weatherLatitude = 31.2304;
        weatherLongitude = 121.4737;
        sidebarModuleOrder = defaultSidebarModuleOrder();
        save();
    }

    function load() {
        // Forces singleton construction from shell.qml.
    }

    onShowActiveWindowIconChanged: scheduleSave()
    onShowEmptyWorkspacesChanged: scheduleSave()
    onShadowEnabledChanged: scheduleSave()
    onShadowBlurRadiusChanged: scheduleSave()
    onShadowOpacityChanged: scheduleSave()
    onShadowOffsetYChanged: scheduleSave()
    onScreenCornerColorChanged: scheduleSave()
    onAnimationDurationChanged: scheduleSave()
    onPopupBezierX1Changed: scheduleSave()
    onPopupBezierY1Changed: scheduleSave()
    onPopupBezierX2Changed: scheduleSave()
    onPopupBezierY2Changed: scheduleSave()
    onBarFontFamilyChanged: scheduleSave()
    onMonospaceFontFamilyChanged: scheduleSave()
    onBarFontSizeChanged: scheduleSave()
    onScaleChanged: scheduleSave()
    onLanguageChanged: scheduleSave()
    onTimeFormatChanged: scheduleSave()
    onDateFormatChanged: scheduleSave()
    onBarCenterAlignmentChanged: scheduleSave()
    onCalendarWeekStartChanged: scheduleSave()
    onClipboardMaxEntryMbChanged: scheduleSave()
    onClipboardMaxEntriesChanged: scheduleSave()
    onDoNotDisturbChanged: scheduleSave()
    onWallpaperDirectoryChanged: scheduleSave()
    onWallpaperAutoThemeChanged: scheduleSave()
    onWallpaperFillModeChanged: scheduleSave()
    onWallpaperTransitionChanged: scheduleSave()
    onShowCpuUsageChanged: scheduleSave()
    onShowMemoryUsageChanged: scheduleSave()
    onShowCpuTemperatureChanged: scheduleSave()
    onUserAvatarPathChanged: scheduleSave()
    onWeatherLocationNameChanged: scheduleSave()
    onWeatherLatitudeChanged: scheduleSave()
    onWeatherLongitudeChanged: scheduleSave()
    onSidebarModuleOrderChanged: scheduleSave()

    Component.onCompleted: directoryProcess.running = true

    Timer {
        id: saveTimer
        interval: 120
        onTriggered: root.save()
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", root.stateDirectory]
        onExited: root.storageReady = true
    }

    FileView {
        id: settingsStorage

        path: root.storageReady ? root.settingsFilePath : "/dev/null"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            if (root.storageReady)
                root.applySavedSettings(text());
        }
        onLoadFailed: error => {
            if (!root.storageReady)
                return;
            root.ready = true;
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => root.save());
        }
    }

    IpcHandler {
        target: "settings"

        function setLanguage(language: string): void {
            if (language === "zh_CN" || language === "en_US")
                root.language = language;
        }

        function setTimeFormat(format: string): void {
            const value = format.trim();
            if (value)
                root.timeFormat = value.slice(0, 64);
        }

        function setDateFormat(format: string): void {
            const value = format.trim();
            if (value)
                root.dateFormat = value.slice(0, 64);
        }

        function setBarCenterAlignment(mode: string): void {
            if (["group", "clock"].indexOf(mode) >= 0)
                root.barCenterAlignment = mode;
        }

        function setCalendarWeekStart(day: int): void {
            if ([-1, 0, 1, 6].indexOf(day) >= 0)
                root.calendarWeekStart = day;
        }

        function setWallpaperFillMode(mode: string): void {
            if ([
                    "Stretch",
                    "PreserveAspectFit",
                    "PreserveAspectCrop",
                    "Tile",
                    "TileVertically",
                    "TileHorizontally",
                    "Pad"
                ].indexOf(mode) >= 0)
                root.wallpaperFillMode = mode;
        }

        function setWallpaperTransition(transition: string): void {
            if ([
                    "none", "fade", "wipe", "disc", "stripes",
                    "iris", "pixelate", "portal", "random"
                ].indexOf(transition) >= 0)
                root.wallpaperTransition = transition;
        }

        function setScreenCornerColor(color: string): void {
            if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(color))
                root.screenCornerColor = color;
        }

        function reset(): void {
            root.resetDefaults();
        }

        function status(): string {
            return JSON.stringify({
                showActiveWindowIcon: root.showActiveWindowIcon,
                showEmptyWorkspaces: root.showEmptyWorkspaces,
                shadowEnabled: root.shadowEnabled,
                shadowBlurRadius: root.shadowBlurRadius,
                shadowOpacity: root.shadowOpacity,
                shadowOffsetY: root.shadowOffsetY,
                screenCornerColor: root.screenCornerColor,
                animationDuration: root.animationDuration,
                popupBezier: root.popupBezierCurve,
                barFontFamily: root.barFontFamily,
                monospaceFontFamily: root.monospaceFontFamily,
                barFontSize: root.barFontSize,
                scale: root.scale,
                language: root.language,
                timeFormat: root.timeFormat,
                dateFormat: root.dateFormat,
                barCenterAlignment: root.barCenterAlignment,
                calendarWeekStart: root.calendarWeekStart,
                clipboardMaxEntryMb: root.clipboardMaxEntryMb,
                clipboardMaxEntries: root.clipboardMaxEntries,
                doNotDisturb: root.doNotDisturb,
                wallpaperDirectory: root.wallpaperDirectory,
                wallpaperAutoTheme: root.wallpaperAutoTheme,
                wallpaperFillMode: root.wallpaperFillMode,
                wallpaperTransition: root.wallpaperTransition,
                showCpuUsage: root.showCpuUsage,
                showMemoryUsage: root.showMemoryUsage,
                showCpuTemperature: root.showCpuTemperature,
                userAvatarPath: root.userAvatarPath,
                weatherLocationName: root.weatherLocationName,
                weatherLatitude: root.weatherLatitude,
                weatherLongitude: root.weatherLongitude,
                sidebarModuleOrder: root.sidebarModuleOrder
            });
        }
    }
}
