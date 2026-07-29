pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property var entries: []
    property bool available: false
    property bool refreshing: false

    readonly property string historyDirectory:
        ShellSettings.stateDirectory + "/clipboard"
    readonly property string scriptPath: stripFileProtocol(
        Qt.resolvedUrl("../scripts/clipboard_history.py"))
    readonly property int maxBytes:
        ShellSettings.clipboardMaxEntryMb * 1024 * 1024

    function stripFileProtocol(path) {
        return String(path).replace(/^file:\/\//, "");
    }

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function refresh() {
        if (listProcess.running) {
            refreshAgain = true;
            return;
        }
        listProcess.buffer = [];
        refreshing = true;
        listProcess.running = true;
    }

    function copyEntry(entryId) {
        copyProcess.entryId = String(entryId);
        copyProcess.running = true;
    }

    function deleteEntry(entryId) {
        deleteProcess.entryId = String(entryId);
        deleteProcess.running = true;
    }

    function clearHistory() {
        clearProcess.running = true;
    }

    function restartWatcher() {
        watcher.running = false;
        pruneProcess.running = true;
        watcherRestart.restart();
    }

    property bool refreshAgain: false

    Component.onCompleted: {
        watcher.running = true;
        refreshDelay.restart();
    }

    Connections {
        target: ShellSettings

        function onClipboardMaxEntryMbChanged() {
            root.restartWatcher();
        }

        function onClipboardMaxEntriesChanged() {
            root.restartWatcher();
        }
    }

    Timer {
        id: watcherRestart

        interval: 180
        onTriggered: watcher.running = true
    }

    Timer {
        id: refreshDelay

        interval: 80
        onTriggered: root.refresh()
    }

    Process {
        id: watcher

        command: [
            "python3", root.scriptPath, "watch",
            root.historyDirectory, String(root.maxBytes),
            String(ShellSettings.clipboardMaxEntries)
        ]
        stdout: SplitParser {
            onRead: _ => refreshDelay.restart()
        }
        onStarted: root.available = true
        onExited: (exitCode, exitStatus) => {
            root.available = false;
            if (!watcherRestart.running)
                watcherRestart.restart();
        }
    }

    Process {
        id: listProcess

        property var buffer: []
        command: [
            "python3", root.scriptPath, "list", root.historyDirectory
        ]
        stdout: SplitParser {
            onRead: line => {
                try {
                    listProcess.buffer.push(JSON.parse(line));
                } catch (error) {
                    console.warn("ClipboardService: invalid entry:", error);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.entries = listProcess.buffer;
            root.refreshing = false;
            if (root.refreshAgain) {
                root.refreshAgain = false;
                Qt.callLater(() => root.refresh());
            }
        }
    }

    Process {
        id: copyProcess

        property string entryId: ""
        command: [
            "python3", root.scriptPath, "copy",
            root.historyDirectory, entryId
        ]
        onExited: refreshDelay.restart()
    }

    Process {
        id: deleteProcess

        property string entryId: ""
        command: [
            "python3", root.scriptPath, "delete",
            root.historyDirectory, entryId
        ]
        onExited: refreshDelay.restart()
    }

    Process {
        id: clearProcess

        command: [
            "python3", root.scriptPath, "clear", root.historyDirectory
        ]
        onExited: refreshDelay.restart()
    }

    Process {
        id: pruneProcess

        command: [
            "python3", root.scriptPath, "prune",
            root.historyDirectory,
            String(ShellSettings.clipboardMaxEntries),
            String(root.maxBytes)
        ]
        onExited: refreshDelay.restart()
    }
}
