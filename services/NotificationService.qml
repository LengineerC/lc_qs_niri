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
    property bool historyReady: false
    property bool directoryReady: false
    property int sequence: 0

    readonly property var unreadEntries:
        entries.filter(entry => entry && !entry.read)
    readonly property var historyEntries:
        entries.filter(entry => entry && entry.read)
    readonly property var popupEntries:
        entries.filter(entry => entry && entry.popup)
    readonly property int unreadCount: unreadEntries.length
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
            entries = [...liveEntries, ...restored]
                .slice(0, maxHistoryEntries);
        } catch (error) {
            console.warn("NotificationService: cannot load history:", error);
            entries = [];
        }
        historyReady = true;
    }

    function touchEntries() {
        entries = entries.slice();
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

        entries = [entry, ...entries].slice(0, maxHistoryEntries);
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

        const visible = popupEntries;
        if (visible.length < maxVisiblePopups) {
            startPopup(entry);
            return;
        }

        entry.pendingPopup = true;
        const removable = visible.filter(item => !item.closing);
        if (removable.length > 0) {
            // entries and popupEntries are newest-first, so the final
            // non-closing item is the oldest visible notification.
            requestHidePopup(removable[removable.length - 1].notificationId);
        } else {
            // Every visible slot is already leaving. Keep only the newest
            // pending items instead of creating a delayed second batch.
            const pending = entries.filter(item =>
                item && item.pendingPopup && item !== entry);
            const allowedPending = visible.length;
            if (pending.length >= allowedPending)
                pending[pending.length - 1].pendingPopup = false;
            touchEntries();
        }
    }

    function showPendingPopups() {
        if (doNotDisturb)
            return;
        let freeSlots = maxVisiblePopups - popupEntries.length;
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

    function requestHidePopup(notificationId) {
        const entry = entryById(notificationId);
        if (!entry || !entry.popup || entry.closing)
            return;
        stopPopupTimer(entry);
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
                requestHidePopup(entry.notificationId);
            else
                stopPopupTimer(entry);
        });
        touchEntries();
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
        stopPopupTimer(entry);
        stopExitTimer(entry);
        dismissLiveNotification(entry);
        entries = entries.filter(item =>
            item.notificationId !== notificationId);
        scheduleSave();
        showPendingPopups();
    }

    function clearHistory() {
        const removed = entries.filter(entry => entry && entry.read);
        removed.forEach(entry => {
            stopPopupTimer(entry);
            stopExitTimer(entry);
            dismissLiveNotification(entry);
        });
        entries = entries.filter(entry => entry && !entry.read);
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

        let invoked = false;
        const liveActions = entry.notification?.actions ?? [];
        if (liveActions.length > 0) {
            const defaultAction = liveActions.find(action =>
                action.identifier === "default") ?? liveActions[0];
            if (defaultAction) {
                defaultAction.invoke();
                invoked = true;
            }
        }

        if (!invoked) {
            const desktop = desktopEntryFor(entry);
            if (desktop)
                desktop.execute();
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
                requestHidePopup(entry.notificationId);
        });
        touchEntries();
    }

    Component.onCompleted: directoryProcess.running = true

    Timer {
        id: saveTimer
        interval: 120
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
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => root.saveHistory());
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
                doNotDisturb: root.doNotDisturb
            });
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
