pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    readonly property int defaultDurationSeconds: 5 * 60
    readonly property int currentDurationSeconds: durationSeconds

    property string mode: "default"
    property int durationSeconds: defaultDurationSeconds
    property bool running: false
    property int remainingSeconds: defaultDurationSeconds
    property double deadlineMs: 0

    readonly property real progress: currentDurationSeconds > 0
        ? Math.max(0, Math.min(1,
            remainingSeconds / currentDurationSeconds))
        : 0

    function updateRemaining(): void {
        if (!running)
            return;

        remainingSeconds = Math.max(0,
            Math.ceil((deadlineMs - Date.now()) / 1000));

        if (remainingSeconds === 0) {
            running = false;
            deadlineMs = 0;
            completionNotification.exec([
                "notify-send",
                "--app-name=QuickShell",
                "--icon=appointment-soon",
                "--urgency=normal",
                I18n.tr("timerComplete"),
                I18n.tr("timerCompleteBody")
            ]);
        }
    }

    function toggle(): void {
        if (running) {
            updateRemaining();
            running = false;
            deadlineMs = 0;
            return;
        }

        if (remainingSeconds <= 0)
            remainingSeconds = currentDurationSeconds;

        deadlineMs = Date.now() + remainingSeconds * 1000;
        running = true;
    }

    function reset(): void {
        running = false;
        deadlineMs = 0;
        remainingSeconds = currentDurationSeconds;
    }

    function setDuration(seconds: int): void {
        durationSeconds = Math.max(1, Math.min(
            99 * 3600 + 59 * 60 + 59,
            Math.round(seconds)));
        mode = "custom";
        reset();
    }

    Process {
        id: completionNotification
    }

    Timer {
        interval: 200
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateRemaining()
    }
}
