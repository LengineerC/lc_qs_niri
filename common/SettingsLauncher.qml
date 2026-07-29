import QtQuick
import Quickshell
pragma Singleton

Singleton {
    signal openRequested()
    signal closeRequested()
    signal toggleRequested()

    function open() {
        openRequested();
    }

    function close() {
        closeRequested();
    }

    function toggle() {
        toggleRequested();
    }

}
