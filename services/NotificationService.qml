pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.common

Singleton {
    id: root

    component NotificationEntry: QtObject {
        required property string notificationId
        property var notification: null
        property string appName: ""
        property string appIcon: ""
        property string desktopEntry: ""
        property string summary: ""
        property string body: ""
        property string image: ""
        property int urgency: NotificationUrgency.Normal
        property var actions: []
        property double timestamp: Date.now()
        property bool read: false
        property bool popup: false
        property bool pendingPopup: false
        property bool closing: false
        property bool toastPresented: false
        property bool disposalQueued: false
        property int popupTimeoutMs: 7000
        property Timer popupTimer: null
        property Timer exitTimer: null
    }

    component NotificationTimer: Timer {
        required property string notificationId
        running: true
        repeat: false
        onTriggered: {
            root.hidePopup(notificationId);
        }
    }

    component NotificationExitTimer: Timer {
        required property string notificationId
        interval: root.toastExitDuration
        running: true
        repeat: false
        onTriggered: {
            root.finalizeHidePopup(notificationId);
            destroy();
        }
    }

    property var entries: []
    // View models are refreshed at most once per frame. Keeping these as
    // cached arrays prevents every entry property change in a bulk operation
    // from re-running filters and resetting all QML delegates.
    property var unreadEntries: []
    property var historyEntries: []
    property var popupEntries: []
    property var centerEntries: []
    property var pendingEntryDisposals: []
    property bool historyReady: false
    property bool directoryReady: false
    property int sequence: 0
    property string panelOutputName: ""
    property string pendingPanelAction: ""
    property int panelRequestRevision: 0
    property int activePanelRequestRevision: -1

    readonly property int unreadCount: unreadEntries.length
    readonly property bool panelVisible: panelOutputName.length > 0
    readonly property int maxVisiblePopups: 5
    readonly property int toastExitDuration: Math.max(160,
        Math.min(320, Math.round(ShellSettings.animationDuration * 0.55)))
    readonly property bool doNotDisturb: ShellSettings.doNotDisturb
    readonly property string historyDirectory:
        ShellSettings.stateDirectory + "/notifications"
    readonly property string historyFile:
        historyDirectory + "/history.json"
    readonly property int maxHistoryEntries: 200

    signal received(var entry)
    signal panelActionRequested(string action, string outputName)

    Component {
        id: entryComponent
        NotificationEntry {}
    }

    Component {
        id: timerComponent
        NotificationTimer {}
    }

    Component {
        id: exitTimerComponent
        NotificationExitTimer {}
    }

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function updatePanelVisibility(outputName, visible) {
        const name = String(outputName ?? "");
        if (visible) {
            panelOutputName = name;
        } else if (panelOutputName === name) {
            panelOutputName = "";
        }
    }

    function cancelPanelOutputRequest() {
        ++panelRequestRevision;
        pendingPanelAction = "";
    }

    function requestPanelAction(action) {
        ++panelRequestRevision;
        pendingPanelAction = action;

        if (!panelOutputProcess.running)
            startPanelOutputRequest();
    }

    function startPanelOutputRequest() {
        if (pendingPanelAction.length === 0
                || panelOutputProcess.running) {
            return;
        }

        activePanelRequestRevision = panelRequestRevision;
        panelOutputProcess.output = "";
        panelOutputProcess.exec([
            "niri", "msg", "--json", "focused-output"
        ]);
    }

    function openPanel() {
        requestPanelAction("open");
    }

    function closePanel() {
        cancelPanelOutputRequest();
        panelOutputName = "";
        panelActionRequested("close", "");
    }

    function togglePanel() {
        requestPanelAction("toggle");
    }

    function handlePanelOutputResult(outputText, completedRevision) {
        if (completedRevision !== panelRequestRevision
                || completedRevision !== activePanelRequestRevision) {
            return;
        }

        const action = pendingPanelAction;
        pendingPanelAction = "";
        if (action.length === 0)
            return;

        try {
            const output = JSON.parse(String(outputText ?? "").trim());
            const outputName = String(output?.name ?? "");
            if (outputName.length === 0) {
                console.warn("Niri focused output has no name:", outputText);
                return;
            }
            panelActionRequested(action, outputName);
        } catch (error) {
            console.warn("Failed to parse niri focused output:",
                outputText, error);
        }
    }

    function nextId(sourceId) {
        sequence += 1;
        return String(sourceId) + "-" + String(Date.now())
            + "-" + String(sequence);
    }

    function plainText(value) {
        return String(value ?? "")
            .replace(/<img\b[^>]*>/gi, "")
            .replace(/<br\s*\/?>/gi, "\n")
            .replace(/<[^>]+>/g, "")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&amp;/g, "&")
            .replace(/&quot;/g, "\"");
    }

    function resolveAppName(notification) {
        if (notification.appName)
            return notification.appName;
        const desktop = DesktopEntries.heuristicLookup(
            notification.desktopEntry);
        return desktop?.name ?? I18n.tr("unknownApplication");
    }

    function normaliseImageSource(source) {
        const value = String(source ?? "").trim();
        if (!value)
            return "";
        if (value.startsWith("/"))
            return "file://" + value;
        return value;
    }

    function resolveNotificationImage(notification) {
        const image = normaliseImageSource(notification?.image);
        if (image)
            return image;

        // Quickshell normally promotes the freedesktop image hints to
        // notification.image. Keep these path fallbacks for clients that
        // expose a non-standard spelling instead.
        const hints = notification?.hints ?? {};
        return normaliseImageSource(
            hints["image-path"] ?? hints["image_path"] ?? "");
    }

    function invalidateImage(entry, failedSource) {
        if (!entry)
            return;
        const current = normaliseImageSource(entry.image);
        if (!current || current !== normaliseImageSource(failedSource))
            return;

        // Do not retry a broken or half-written image every time a toast is
        // recycled or the notification center is opened.
        entry.image = "";
        scheduleSave();
    }

    function serialiseEntry(entry) {
        return {
            notificationId: entry.notificationId,
            appName: entry.appName,
            appIcon: entry.appIcon,
            desktopEntry: entry.desktopEntry,
            summary: entry.summary,
            body: entry.body,
            image: String(entry.image).startsWith("image://qsimage/")
                ? "" : entry.image,
            urgency: entry.urgency,
            timestamp: entry.timestamp,
            read: entry.read
        };
    }

    function scheduleSave() {
        if (historyReady && directoryReady)
            saveTimer.restart();
    }

    function sameEntryList(first, second) {
        if (first.length !== second.length)
            return false;
        for (let index = 0; index < first.length; ++index) {
            if (first[index] !== second[index])
                return false;
        }
        return true;
    }

    function scheduleViewRefresh() {
        if (!viewRefreshTimer.running)
            viewRefreshTimer.start();
    }

    function flushEntryViews() {
        viewRefreshTimer.stop();

        const unread = [];
        const history = [];
        const popups = [];
        for (let index = 0; index < entries.length; ++index) {
            const entry = entries[index];
            if (!entry)
                continue;
            if (entry.read)
                history.push(entry);
            else
                unread.push(entry);
            if (entry.popup)
                popups.push(entry);
        }

        if (!sameEntryList(unreadEntries, unread))
            unreadEntries = unread;
        if (!sameEntryList(historyEntries, history))
            historyEntries = history;
        if (!sameEntryList(popupEntries, popups))
            popupEntries = popups;

        const centered = unread.concat(history);
        if (!sameEntryList(centerEntries, centered))
            centerEntries = centered;

        const disposals = pendingEntryDisposals;
        pendingEntryDisposals = [];
        if (disposals.length > 0) {
            // Let Repeaters/ListViews release their references first.
            Qt.callLater(() => {
                disposals.forEach(entry => {
                    if (entry)
                        entry.destroy();
                });
            });
        }
    }

    function queueEntryDisposal(entry) {
        if (!entry || entry.disposalQueued)
            return;
        entry.disposalQueued = true;
        stopPopupTimer(entry);
        stopExitTimer(entry);
        entry.popup = false;
        entry.pendingPopup = false;
        dismissLiveNotification(entry);
        // This array is internal and has no bindings, so mutate it in place
        // to avoid repeatedly copying an increasingly large disposal queue.
        pendingEntryDisposals.push(entry);
    }

    function saveHistory() {
        if (!directoryReady)
            return;
        const data = entries.slice(0, maxHistoryEntries)
            .map(entry => serialiseEntry(entry));
        historyStorage.setText(JSON.stringify({
            version: 1,
            notifications: data
        }, null, 2));
    }

    function loadHistory(data) {
        try {
            const parsed = JSON.parse(data);
            const stored = Array.isArray(parsed)
                ? parsed : parsed.notifications;
            if (!Array.isArray(stored))
                throw new Error("Invalid notification history");

            const restored = stored.slice(0, maxHistoryEntries).map(data => {
                return entryComponent.createObject(root, {
                    notificationId: String(data.notificationId
                        ?? root.nextId("history")),
                    appName: String(data.appName ?? ""),
                    appIcon: String(data.appIcon ?? ""),
                    desktopEntry: String(data.desktopEntry ?? ""),
                    summary: String(data.summary ?? ""),
                    body: String(data.body ?? ""),
                    image: String(data.image ?? ""),
                    urgency: Number(data.urgency
                        ?? NotificationUrgency.Normal),
                    timestamp: Number(data.timestamp ?? Date.now()),
                    // Entries restored after a shell restart are history.
                    read: true,
                    popup: false,
                    actions: []
                });
            });
            // Do not lose notifications received while the history file was
            // still loading during shell startup.
            const liveEntries = entries.filter(entry =>
                entry && entry.notification);
            const combined = [...liveEntries, ...restored];
            entries = combined.slice(0, maxHistoryEntries);
            combined.slice(maxHistoryEntries)
                .forEach(entry => queueEntryDisposal(entry));
        } catch (error) {
            console.warn("NotificationService: cannot load history:", error);
            entries = [];
        }
        historyReady = true;
        flushEntryViews();
    }

    function touchEntries() {
        scheduleViewRefresh();
        scheduleSave();
    }

    function entryById(notificationId) {
        return entries.find(entry =>
            entry.notificationId === notificationId) ?? null;
    }

    function popupTimeout(notification) {
        if (notification.expireTimeout === 0)
            return 0;
        return notification.expireTimeout > 0
            ? Math.max(1000, notification.expireTimeout) : 7000;
    }

    function watchNotificationLifecycle(entry) {
        if (!entry?.notification)
            return;

        const liveNotification = entry.notification;
        const entryId = entry.notificationId;

        liveNotification.closed.connect(reason => {
            const currentEntry = root.entryById(entryId);
            if (!currentEntry)
                return;

            currentEntry.notification = null;

            if (reason === NotificationCloseReason.CloseRequested)
                root.markRead(entryId);
        });
    }

    function addNotification(notification) {
        notification.tracked = true;
        const timeout = popupTimeout(notification);
        const actionData = notification.actions.map(action => ({
            identifier: action.identifier,
            text: action.text
        }));
        const entry = entryComponent.createObject(root, {
            notificationId: nextId(notification.id),
            notification: notification,
            appName: resolveAppName(notification),
            appIcon: notification.appIcon ?? "",
            desktopEntry: notification.desktopEntry ?? "",
            summary: plainText(notification.summary),
            body: plainText(notification.body),
            image: resolveNotificationImage(notification),
            urgency: notification.urgency,
            actions: actionData,
            timestamp: Date.now(),
            read: false,
            popup: false,
            pendingPopup: false,
            closing: false,
            popupTimeoutMs: timeout
        });

        const combined = [entry, ...entries];
        entries = combined.slice(0, maxHistoryEntries);
        combined.slice(maxHistoryEntries)
            .forEach(oldEntry => queueEntryDisposal(oldEntry));
        watchNotificationLifecycle(entry);
        if (!doNotDisturb)
            queuePopup(entry);
        scheduleSave();
        received(entry);
    }

    function startPopup(entry) {
        if (!entry || doNotDisturb)
            return;
        entry.pendingPopup = false;
        entry.closing = false;
        entry.popup = true;
        if (entry.popupTimeoutMs > 0) {
            entry.popupTimer = timerComponent.createObject(entry, {
                notificationId: entry.notificationId,
                interval: entry.popupTimeoutMs
            });
        }
        touchEntries();
    }

    function queuePopup(entry) {
        if (!entry || doNotDisturb)
            return;

        // The published popup model is frame-coalesced, so derive the small
        // internal working set from the authoritative entries array.
        const visible = entries.filter(item => item && item.popup);
        if (visible.length < maxVisiblePopups) {
            startPopup(entry);
            return;
        }

        entry.pendingPopup = true;
        const hasClosingPopup = visible.some(item => item.closing);
        if (!hasClosingPopup) {
            // entries and popupEntries are newest-first, so the final
            // item is the oldest visible notification. Only retire one card
            // at a time so a burst cannot start five simultaneous effects.
            requestHidePopup(visible[visible.length - 1].notificationId);
        } else {
            // Keep only the newest waiting toast. Every notification remains
            // in the center, but stale popups are not animated after a burst.
            const pending = entries.filter(item =>
                item && item.pendingPopup && item !== entry);
            pending.forEach(item => item.pendingPopup = false);
            touchEntries();
        }
    }

    function showPendingPopups() {
        if (doNotDisturb)
            return;
        const visible = entries.filter(entry => entry && entry.popup);
        let freeSlots = maxVisiblePopups - visible.length;
        if (freeSlots <= 0)
            return;

        const pending = entries.filter(entry =>
            entry && entry.pendingPopup);
        for (let index = 0;
                index < pending.length && freeSlots > 0; ++index) {
            startPopup(pending[index]);
            freeSlots -= 1;
        }
    }

    function stopPopupTimer(entry) {
        if (!entry?.popupTimer)
            return;
        entry.popupTimer.stop();
        entry.popupTimer.destroy();
        entry.popupTimer = null;
    }

    function stopExitTimer(entry) {
        if (!entry?.exitTimer)
            return;
        entry.exitTimer.stop();
        entry.exitTimer.destroy();
        entry.exitTimer = null;
    }

    function requestHidePopup(notificationId, showPending = true) {
        const entry = entryById(notificationId);
        if (!entry || !entry.popup || entry.closing)
            return;
        stopPopupTimer(entry);

        // A burst can replace a toast before its delegate reached the screen.
        // There is nothing to animate in that case, so release the slot now
        // instead of creating an exit timer and an invisible animation.
        if (!entry.toastPresented) {
            entry.popup = false;
            entry.closing = false;
            touchEntries();
            if (showPending)
                showPendingPopups();
            return;
        }

        entry.closing = true;
        entry.exitTimer = exitTimerComponent.createObject(entry, {
            notificationId: entry.notificationId
        });
        touchEntries();
    }

    function finalizeHidePopup(notificationId) {
        const entry = entryById(notificationId);
        if (!entry)
            return;
        entry.exitTimer = null;
        entry.popup = false;
        entry.closing = false;
        touchEntries();
        showPendingPopups();
    }

    function hidePopup(notificationId) {
        requestHidePopup(notificationId);
    }

    function markRead(notificationId) {
        const entry = entryById(notificationId);
        if (!entry)
            return;
        entry.read = true;
        entry.pendingPopup = false;
        if (entry.popup)
            requestHidePopup(notificationId);
        else
            stopPopupTimer(entry);
        touchEntries();
    }

    function markAllRead() {
        entries.forEach(entry => {
            if (!entry)
                return;
            entry.read = true;
            entry.pendingPopup = false;
            if (entry.popup)
                requestHidePopup(entry.notificationId, false);
            else
                stopPopupTimer(entry);
        });
        // Publish one model change for the complete batch instead of one
        // change per entry.
        flushEntryViews();
        scheduleSave();
    }

    function dismissLiveNotification(entry) {
        if (!entry)
            return;
        try {
            const liveNotification = entry.notification;
            if (liveNotification
                    && typeof liveNotification.dismiss === "function") {
                liveNotification.dismiss();
            }
        } catch (error) {
            // A sender can disappear before its history entry is cleared.
            console.debug("NotificationService: live notification expired");
        }
    }

    function removeEntry(notificationId) {
        const entry = entryById(notificationId);
        if (!entry)
            return;
        entries = entries.filter(item =>
            item.notificationId !== notificationId);
        queueEntryDisposal(entry);
        scheduleViewRefresh();
        scheduleSave();
        showPendingPopups();
    }

    function clearHistory() {
        const removed = entries.filter(entry => entry && entry.read);
        entries = entries.filter(entry => entry && !entry.read);
        removed.forEach(entry => queueEntryDisposal(entry));
        flushEntryViews();
        scheduleSave();
        showPendingPopups();
    }

    function desktopEntryFor(entry) {
        if (!entry)
            return null;
        let desktop = null;
        if (entry.desktopEntry)
            desktop = DesktopEntries.heuristicLookup(entry.desktopEntry);
        if (!desktop && entry.appName)
            desktop = DesktopEntries.heuristicLookup(entry.appName);
        return desktop;
    }

    function iconSource(entry) {
        if (!entry)
            return Quickshell.iconPath("dialog-information");
        if (entry.appIcon)
            return Quickshell.iconPath(entry.appIcon,
                "dialog-information");
        const desktop = desktopEntryFor(entry);
        return desktop?.icon
            ? Quickshell.iconPath(desktop.icon, "dialog-information")
            : Quickshell.iconPath("dialog-information");
    }

    function hasApplicationIcon(entry) {
        if (!entry)
            return false;
        if (entry.appIcon)
            return true;
        return Boolean(desktopEntryFor(entry)?.icon);
    }

    function hasNotificationImage(entry) {
        return normaliseImageSource(entry?.image) !== "";
    }

    function avatarSource(entry) {
        const image = normaliseImageSource(entry?.image);
        return image || iconSource(entry);
    }

    function activate(entry) {
        if (!entry)
            return;

        const notification = entry.notification;
        const liveActions = notification?.actions ?? [];
        const primaryAction = liveActions.find(action =>
            action.identifier === "default")
            ?? liveActions[0]
            ?? null;
        let activated = false;

        if (primaryAction) {
            try {
                primaryAction.invoke();
                activated = true;
            } catch (error) {
                console.warn(
                    "NotificationService: action invocation failed:",
                    error
                );
            }
        }

        if (!activated) {
            console.debug(
                "NotificationService: notification is no longer actionable:",
                entry.notificationId
            );
        }

        markRead(entry.notificationId);
    }

    onDoNotDisturbChanged: {
        if (!doNotDisturb)
            return;
        entries.forEach(entry => {
            if (!entry)
                return;
            stopPopupTimer(entry);
            entry.pendingPopup = false;
            if (entry.popup)
                requestHidePopup(entry.notificationId, false);
        });
        flushEntryViews();
        scheduleSave();
    }

    Component.onCompleted: directoryProcess.running = true

    Timer {
        id: viewRefreshTimer
        interval: 16
        repeat: false
        onTriggered: root.flushEntryViews()
    }

    Timer {
        id: saveTimer
        // Bursty clients can otherwise start many asynchronous history writes
        // while images and toast delegates are being created.
        interval: 1000
        onTriggered: root.saveHistory()
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", root.historyDirectory]
        onExited: {
            root.directoryReady = true;
            historyStorage.reload();
        }
    }

    FileView {
        id: historyStorage
        path: root.directoryReady ? root.historyFile : "/dev/null"
        printErrors: false

        onLoaded: root.loadHistory(text())
        onLoadFailed: error => {
            if (!root.directoryReady)
                return;
            root.entries = [];
            root.historyReady = true;
            root.flushEntryViews();
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => root.saveHistory());
        }
    }

    Process {
        id: panelOutputProcess

        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: panelOutputProcess.output = this.text
        }

        stderr: StdioCollector {
            id: panelOutputError
        }

        onExited: (exitCode, exitStatus) => {
            const completedRevision = root.activePanelRequestRevision;

            if (exitCode === 0) {
                root.handlePanelOutputResult(
                    panelOutputProcess.output, completedRevision);
            } else {
                if (completedRevision === root.panelRequestRevision)
                    root.pendingPanelAction = "";
                console.warn("Failed to query niri focused output:",
                    exitCode, exitStatus, panelOutputError.text);
            }

            root.activePanelRequestRevision = -1;
            if (root.pendingPanelAction.length > 0)
                Qt.callLater(() => root.startPanelOutputRequest());
        }
    }

    IpcHandler {
        target: "notifications"

        function status(): string {
            return JSON.stringify({
                unread: root.unreadCount,
                visible: root.popupEntries.length,
                closing: root.popupEntries.filter(entry =>
                    entry.closing).length,
                pending: root.entries.filter(entry =>
                    entry && entry.pendingPopup).length,
                history: root.historyEntries.length,
                doNotDisturb: root.doNotDisturb,
                panelVisible: root.panelVisible,
                panelOutput: root.panelOutputName
            });
        }

        function open(): void {
            root.openPanel();
        }

        function close(): void {
            root.closePanel();
        }

        function toggle(): void {
            root.togglePanel();
        }

        function visible(): bool {
            return root.panelVisible;
        }

        function markAllRead(): void {
            root.markAllRead();
        }

        function clearHistory(): void {
            root.clearHistory();
        }

        function setDoNotDisturb(enabled: bool): void {
            ShellSettings.doNotDisturb = enabled;
        }
    }

    NotificationServer {
        id: notificationServer

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: false

        onNotification: notification => root.addNotification(notification)
    }
}
