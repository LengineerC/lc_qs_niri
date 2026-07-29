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
    property int animationDuration: 500
    property real popupBezierX1: 0.38
    property real popupBezierY1: 1.21
    property real popupBezierX2: 0.22
    property real popupBezierY2: 1.00
    property string barFontFamily: "JetBrainsMono Nerd Font"
    property int barFontSize: 13
    property real scale: 1.00
    property string language: "zh_CN"
    property string timeFormat: "HH:mm"
    property string dateFormat: "MMM dd ddd"
    property int clipboardMaxEntryMb: 10
    property int clipboardMaxEntries: 100
    property bool doNotDisturb: false
    property string wallpaperDirectory: ""
    property bool wallpaperAutoTheme: true
    property string wallpaperFillMode: "PreserveAspectCrop"
    property bool showCpuUsage: true
    property bool showMemoryUsage: true
    property bool showCpuTemperature: false

    property bool ready: false
    property bool storageReady: false
    property bool applyingState: false

    readonly property string stateDirectory: stripFileProtocol(
        StandardPaths.standardLocations(StandardPaths.StateLocation)[0])
        + "/test"
    readonly property string settingsFilePath: stateDirectory + "/settings.json"
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

    function scheduleSave() {
        if (ready && storageReady && !applyingState)
            saveTimer.restart();
    }

    function save() {
        if (!storageReady || applyingState)
            return;

        settingsStorage.setText(JSON.stringify({
            version: 10,
            showActiveWindowIcon: showActiveWindowIcon,
            showEmptyWorkspaces: showEmptyWorkspaces,
            shadowEnabled: shadowEnabled,
            shadowBlurRadius: shadowBlurRadius,
            shadowOpacity: shadowOpacity,
            shadowOffsetY: shadowOffsetY,
            animationDuration: animationDuration,
            popupBezier: [
                popupBezierX1, popupBezierY1,
                popupBezierX2, popupBezierY2
            ],
            barFontFamily: barFontFamily,
            barFontSize: barFontSize,
            scale: scale,
            language: language,
            timeFormat: timeFormat,
            dateFormat: dateFormat,
            clipboardMaxEntryMb: clipboardMaxEntryMb,
            clipboardMaxEntries: clipboardMaxEntries,
            doNotDisturb: doNotDisturb,
            wallpaperDirectory: wallpaperDirectory,
            wallpaperAutoTheme: wallpaperAutoTheme,
            wallpaperFillMode: wallpaperFillMode,
            showCpuUsage: showCpuUsage,
            showMemoryUsage: showMemoryUsage,
            showCpuTemperature: showCpuTemperature
        }, null, 2));
    }

    function applySavedSettings(data) {
        applyingState = true;
        let needsMigration = false;
        try {
            const state = JSON.parse(data);
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
        animationDuration = 500;
        popupBezierX1 = 0.38;
        popupBezierY1 = 1.21;
        popupBezierX2 = 0.22;
        popupBezierY2 = 1.00;
        barFontFamily = "JetBrainsMono Nerd Font";
        barFontSize = 13;
        scale = 1.00;
        language = "zh_CN";
        timeFormat = "HH:mm";
        dateFormat = "MMM dd ddd";
        clipboardMaxEntryMb = 10;
        clipboardMaxEntries = 100;
        doNotDisturb = false;
        wallpaperDirectory = "";
        wallpaperAutoTheme = true;
        wallpaperFillMode = "PreserveAspectCrop";
        showCpuUsage = true;
        showMemoryUsage = true;
        showCpuTemperature = false;
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
    onAnimationDurationChanged: scheduleSave()
    onPopupBezierX1Changed: scheduleSave()
    onPopupBezierY1Changed: scheduleSave()
    onPopupBezierX2Changed: scheduleSave()
    onPopupBezierY2Changed: scheduleSave()
    onBarFontFamilyChanged: scheduleSave()
    onBarFontSizeChanged: scheduleSave()
    onScaleChanged: scheduleSave()
    onLanguageChanged: scheduleSave()
    onTimeFormatChanged: scheduleSave()
    onDateFormatChanged: scheduleSave()
    onClipboardMaxEntryMbChanged: scheduleSave()
    onClipboardMaxEntriesChanged: scheduleSave()
    onDoNotDisturbChanged: scheduleSave()
    onWallpaperDirectoryChanged: scheduleSave()
    onWallpaperAutoThemeChanged: scheduleSave()
    onWallpaperFillModeChanged: scheduleSave()
    onShowCpuUsageChanged: scheduleSave()
    onShowMemoryUsageChanged: scheduleSave()
    onShowCpuTemperatureChanged: scheduleSave()

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
                animationDuration: root.animationDuration,
                popupBezier: root.popupBezierCurve,
                barFontFamily: root.barFontFamily,
                barFontSize: root.barFontSize,
                scale: root.scale,
                language: root.language,
                timeFormat: root.timeFormat,
                dateFormat: root.dateFormat,
                clipboardMaxEntryMb: root.clipboardMaxEntryMb,
                clipboardMaxEntries: root.clipboardMaxEntries,
                doNotDisturb: root.doNotDisturb,
                wallpaperDirectory: root.wallpaperDirectory,
                wallpaperAutoTheme: root.wallpaperAutoTheme,
                wallpaperFillMode: root.wallpaperFillMode,
                showCpuUsage: root.showCpuUsage,
                showMemoryUsage: root.showMemoryUsage,
                showCpuTemperature: root.showCpuTemperature
            });
        }
    }
}
