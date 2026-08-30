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
    // Full-screen shell surfaces can reuse the Overview bar retraction
    // without pretending that Niri's Overview itself is open.
    property real launchpadProgress: 0
    readonly property real barRetractionProgress: Math.max(
        overviewProgress, Math.max(0, Math.min(1, launchpadProgress)))
    property string lastError: ""
    property var workspaceStates: ({})
    property var windowStates: ({})
    property int stateRevision: 0

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

    function toggleOverview() {
        const result = backend.toggleOverview();
        if (!result.ok) {
            lastError = result.error ?? "Unknown Niri IPC error";
            console.warn("Failed to toggle Niri overview:", lastError);
        }
        return result;
    }

    function moveWorkspaceToIndex(workspaceId, targetIndex) {
        const index = Math.max(1, Math.round(Number(targetIndex)));
        const result = backend.sendRawAction({
            MoveWorkspaceToIndex: {
                index: index,
                reference: {
                    Id: Number(workspaceId)
                }
            }
        });
        if (!result.ok) {
            lastError = result.error ?? "Unknown Niri IPC error";
            console.warn("Failed to reorder Niri workspace:", lastError);
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

    function publishWorkspaceStates(states) {
        workspaceStates = states;
        ++stateRevision;
    }

    function publishWindowStates(states) {
        windowStates = states;
        ++stateRevision;
    }

    function replaceWorkspaces(items) {
        const states = {};
        for (const workspace of items ?? [])
            states[String(workspace.id)] = workspace;
        publishWorkspaceStates(states);
    }

    function replaceWindows(items) {
        const states = {};
        for (const window of items ?? [])
            states[String(window.id)] = window;
        publishWindowStates(states);
    }

    function updateWorkspace(workspaceId, updates) {
        const key = String(workspaceId);
        const current = workspaceStates[key];
        if (!current)
            return;
        const states = Object.assign({}, workspaceStates);
        states[key] = Object.assign({}, current, updates);
        publishWorkspaceStates(states);
    }

    function updateWindow(window) {
        if (!window || window.id === undefined)
            return;
        const states = Object.assign({}, windowStates);
        states[String(window.id)] = window;
        publishWindowStates(states);
    }

    function updateWindowLayouts(changes) {
        const states = Object.assign({}, windowStates);
        let changed = false;
        for (const entry of changes ?? []) {
            if (!Array.isArray(entry) || entry.length < 2)
                continue;
            const key = String(entry[0]);
            if (!states[key])
                continue;
            states[key] = Object.assign({}, states[key], {
                layout: entry[1]
            });
            changed = true;
        }
        if (changed)
            publishWindowStates(states);
    }

    function removeWindow(windowId) {
        const key = String(windowId);
        if (!windowStates[key])
            return;
        const states = Object.assign({}, windowStates);
        delete states[key];
        publishWindowStates(states);
    }

    function activateWorkspace(workspaceId, focused) {
        const key = String(workspaceId);
        const target = workspaceStates[key];
        if (!target)
            return;
        const states = Object.assign({}, workspaceStates);
        for (const stateKey of Object.keys(states)) {
            const workspace = states[stateKey];
            const updates = {};
            if (workspace.output === target.output)
                updates.is_active = stateKey === key;
            if (focused)
                updates.is_focused = stateKey === key;
            if (Object.keys(updates).length > 0)
                states[stateKey] = Object.assign({}, workspace, updates);
        }
        publishWorkspaceStates(states);
    }

    function outputActiveWindowIsFullscreen(outputName, outputWidth,
            outputHeight) {
        // Makes this function binding-reactive even though the state is read
        // through JavaScript maps.
        const revision = stateRevision;
        const width = Number(outputWidth);
        const height = Number(outputHeight);
        if (!outputName || width <= 0 || height <= 0)
            return false;

        let activeWorkspace = null;
        for (const workspace of Object.values(workspaceStates)) {
            if (workspace.output === outputName && workspace.is_active) {
                activeWorkspace = workspace;
                break;
            }
        }
        if (!activeWorkspace)
            return false;

        const activeWindowId = activeWorkspace.active_window_id;
        if (activeWindowId === null || activeWindowId === undefined)
            return false;

        const window = windowStates[String(activeWindowId)];
        if (!window
                || Number(window.workspace_id)
                    !== Number(activeWorkspace.id)) {
            return false;
        }

        // Niri deliberately distinguishes real fullscreen from windowed
        // fullscreen in its layout: a real fullscreen tile matches the full
        // logical output instead of the normal work area reserved by the bar.
        const tolerance = 2.5;
        const size = window.layout?.tile_size;
        return Array.isArray(size) && size.length >= 2
            && Math.abs(Number(size[0]) - width) <= tolerance
            && Math.abs(Number(size[1]) - height) <= tolerance;
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
            root.workspaceStates = ({});
            root.windowStates = ({});
            ++root.stateRevision;
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

            const workspacesChanged = event?.WorkspacesChanged;
            if (workspacesChanged)
                root.replaceWorkspaces(workspacesChanged.workspaces);

            const workspaceActivated = event?.WorkspaceActivated;
            if (workspaceActivated)
                root.activateWorkspace(workspaceActivated.id,
                    workspaceActivated.focused === true);

            const activeWindowChanged = event?.WorkspaceActiveWindowChanged;
            if (activeWindowChanged) {
                root.updateWorkspace(activeWindowChanged.workspace_id, {
                    active_window_id: activeWindowChanged.active_window_id
                });
            }

            const windowsChanged = event?.WindowsChanged;
            if (windowsChanged)
                root.replaceWindows(windowsChanged.windows);

            const windowChanged = event?.WindowOpenedOrChanged;
            if (windowChanged)
                root.updateWindow(windowChanged.window);

            const layoutsChanged = event["WindowLayoutsChanged"];
            if (layoutsChanged)
                root.updateWindowLayouts(layoutsChanged.changes);

            const windowClosed = event?.WindowClosed;
            if (windowClosed)
                root.removeWindow(windowClosed.id);
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
