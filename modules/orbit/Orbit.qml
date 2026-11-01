pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property ShellScreen modelData
            property bool presenting: false
            screen: modelData
            color: "transparent"
            visible: presenting
            exclusiveZone: -1
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:orbit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            function sync() {
                if (OrbitService.shown && OrbitService.outputName === modelData.name) {
                    presenting = true;
                    Qt.callLater(() => content.openAt(OrbitService.originX, OrbitService.originY));
                } else if (presenting) content.close();
            }
            Component.onCompleted: sync()
            Connections {
                target: OrbitService
                function onShownChanged() { window.sync(); }
                function onOutputNameChanged() { window.sync(); }
            }
            OrbitContent {
                id: content
                anchors.fill: parent
                onFinished: window.presenting = false
            }
        }
    }
}
