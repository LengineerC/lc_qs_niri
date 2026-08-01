pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property var tasks: []
    property bool storageReady: false
    property bool initialized: false
    property int idSequence: 0

    function scheduleSave(): void {
        if (initialized && storageReady)
            saveTimer.restart();
    }

    function addTask(value): void {
        const text = String(value ?? "").trim().slice(0, 160);
        if (!text)
            return;

        idSequence++;
        tasks = tasks.concat([{
            id: String(Date.now()) + "-" + idSequence,
            text: text,
            completed: false
        }]);
        scheduleSave();
    }

    function toggleTask(taskId): void {
        tasks = tasks.map(task => task.id === taskId ? {
            id: task.id,
            text: task.text,
            completed: !task.completed
        } : task);
        scheduleSave();
    }

    function deleteTask(taskId): void {
        tasks = tasks.filter(task => task.id !== taskId);
        scheduleSave();
    }

    function save(): void {
        if (!storageReady || !initialized)
            return;

        taskStorage.setText(JSON.stringify({
            version: 1,
            tasks: tasks
        }, null, 2));
    }

    Component.onCompleted: directoryProcess.running = true

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", "--", ShellSettings.stateDirectory]
        onExited: exitCode => {
            if (exitCode === 0)
                root.storageReady = true;
        }
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: root.save()
    }

    FileView {
        id: taskStorage

        path: root.storageReady
            ? ShellSettings.sidebarTasksFilePath : "/dev/null"
        atomicWrites: true
        printErrors: false
        watchChanges: false

        onLoaded: {
            if (!root.storageReady)
                return;

            try {
                const data = JSON.parse(text());
                if (Array.isArray(data.tasks)) {
                    root.tasks = data.tasks.filter(task =>
                        task && typeof task.id === "string"
                        && typeof task.text === "string").map(task => ({
                            id: task.id,
                            text: task.text.slice(0, 160),
                            completed: Boolean(task.completed)
                        }));
                }
            } catch (error) {
                console.warn("TodoService: cannot parse tasks:", error);
            }
            root.initialized = true;
        }

        onLoadFailed: error => {
            if (!root.storageReady)
                return;
            root.initialized = true;
            if (error === FileViewError.FileNotFound)
                Qt.callLater(root.save);
        }
    }
}
