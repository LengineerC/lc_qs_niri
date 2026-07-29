pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Niri
import qs.common

// Shared Niri IPC state for bar and workspace components.
Singleton {
    id: root

    readonly property var workspaces: backend.workspaces
    readonly property var windows: backend.windows
    readonly property var focusedWindow: backend.focusedWindow

    property bool connected: false
    property bool overviewOpen: false
    property real overviewProgress: overviewOpen ? 1 : 0
    property string lastError: ""

    Behavior on overviewProgress {
        NumberAnimation {
            duration: Appearance.spatialDuration / 2
            easing.type: Easing.Linear
        }
    }

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

        onRawEventReceived: event => {
            const overviewEvent = event?.OverviewOpenedOrClosed;
            if (overviewEvent
                    && typeof overviewEvent.is_open === "boolean") {
                root.overviewOpen = overviewEvent.is_open;
            }
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
