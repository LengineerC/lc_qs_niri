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
    property int animationDuration: 500
    property real popupBezierX1: 0.38
    property real popupBezierY1: 1.21
    property real popupBezierX2: 0.22
    property real popupBezierY2: 1.00
    property string barFontFamily: "JetBrainsMono Nerd Font"
    property int barFontSize: 13
    property real scale: 1.00

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
            version: 2,
            showActiveWindowIcon: showActiveWindowIcon,
            showEmptyWorkspaces: showEmptyWorkspaces,
            animationDuration: animationDuration,
            popupBezier: [
                popupBezierX1, popupBezierY1,
                popupBezierX2, popupBezierY2
            ],
            barFontFamily: barFontFamily,
            barFontSize: barFontSize,
            scale: scale
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
        animationDuration = 500;
        popupBezierX1 = 0.38;
        popupBezierY1 = 1.21;
        popupBezierX2 = 0.22;
        popupBezierY2 = 1.00;
        barFontFamily = "JetBrainsMono Nerd Font";
        barFontSize = 13;
        scale = 1.00;
        save();
    }

    function load() {
        // Forces singleton construction from shell.qml.
    }

    onShowActiveWindowIconChanged: scheduleSave()
    onShowEmptyWorkspacesChanged: scheduleSave()
    onAnimationDurationChanged: scheduleSave()
    onPopupBezierX1Changed: scheduleSave()
    onPopupBezierY1Changed: scheduleSave()
    onPopupBezierX2Changed: scheduleSave()
    onPopupBezierY2Changed: scheduleSave()
    onBarFontFamilyChanged: scheduleSave()
    onBarFontSizeChanged: scheduleSave()
    onScaleChanged: scheduleSave()

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

        function reset(): void {
            root.resetDefaults();
        }

        function status(): string {
            return JSON.stringify({
                showActiveWindowIcon: root.showActiveWindowIcon,
                showEmptyWorkspaces: root.showEmptyWorkspaces,
                animationDuration: root.animationDuration,
                popupBezier: root.popupBezierCurve,
                barFontFamily: root.barFontFamily,
                barFontSize: root.barFontSize,
                scale: root.scale
            });
        }
    }
}
