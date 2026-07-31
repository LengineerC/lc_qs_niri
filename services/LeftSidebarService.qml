pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool shown: false

    function load() {
    }

    function open() {
        shown = true;
    }

    function close() {
        shown = false;
    }

    function toggle() {
        shown = !shown;
    }

    IpcHandler {
        target: "leftsidebar"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }

        function isShown(): bool {
            return root.shown;
        }
    }
}