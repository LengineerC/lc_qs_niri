pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool locked: false
    signal lockRequested

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function lock() {
        if (!locked)
            lockRequested();
    }

    IpcHandler {
        target: "lock"

        function open(): void {
            root.lock();
        }

        function isLocked(): bool {
            return root.locked;
        }
    }
}
