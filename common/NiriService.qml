pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Niri

Singleton {
    id: root

    readonly property var workspaces: backend.workspaces
    readonly property var windows: backend.windows
    readonly property var focusedWindow: backend.focusedWindow

    property bool connected: false
    property string lastError: ""

    function focusWorkspaceById(workspaceId) {
        const result = backend.focusWorkspaceById(workspaceId);
        if (!result.ok) {
            lastError = result.error ?? "Unknown Niri IPC error";
            console.warn("Failed to focus Niri workspace:", lastError);
        }
        return result;
    }

    function focusWindow(windowId) {
        const result = backend.focusWindow(windowId);
        if (!result.ok) {
            lastError = result.error ?? "Unknown Niri IPC error";
            console.warn("Failed to focus Niri window:", lastError);
        }
        return result;
    }

    Niri {
        id: backend

        Component.onCompleted: connect()

        onConnected: {
            root.connected = true;
            root.lastError = "";
        }

        onDisconnected: {
            root.connected = false;
            reconnectTimer.restart();
        }

        onErrorOccurred: error => {
            root.connected = false;
            root.lastError = error;
            console.warn("Niri IPC connection error:", error);
            reconnectTimer.restart();
        }
    }

    Timer {
        id: reconnectTimer

        interval: 2000
        onTriggered: {
            if (!backend.isConnected())
                backend.connect();
        }
    }

}
