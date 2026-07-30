pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.common

Scope {
    component ManagedWindow: ApplicationWindow {
        id: managedWindow

        visible: false
        color: Appearance.layer2

        function openWindow() {
            show();
            raise();
            requestActivate();
            Qt.callLater(() => requestActivate());
        }

        function closeWindow() {
            hide();
        }

        function toggleWindow() {
            if (visible)
                closeWindow();
            else
                openWindow();
        }

        onClosing: event => {
            event.accepted = false;
            closeWindow();
        }
    }

    ManagedWindow {
        id: launcherWindow

        title: "QuickShell " + I18n.tr("launcher")
        width: Math.min(screen?.width * 0.72 ?? Appearance.px(540),
            Appearance.px(540))
        height: Math.min(screen?.height * 0.82 ?? Appearance.px(620),
            Appearance.px(620))
        minimumWidth: Appearance.px(420)
        minimumHeight: Appearance.px(390)

        LauncherPanel {
            anchors.fill: parent
            active: launcherWindow.visible
            onCloseRequested: launcherWindow.closeWindow()
        }

        Shortcut {
            sequence: "Escape"
            enabled: launcherWindow.visible
            onActivated: launcherWindow.closeWindow()
        }

        IpcHandler {
            target: "launcher"

            function open(): void {
                launcherWindow.openWindow();
            }

            function close(): void {
                launcherWindow.closeWindow();
            }

            function toggle(): void {
                launcherWindow.toggleWindow();
            }

            function visible(): bool {
                return launcherWindow.visible;
            }
        }
    }

    ManagedWindow {
        id: clipboardWindow

        title: "QuickShell " + I18n.tr("clipboard")
        width: Math.min(screen?.width * 0.72 ?? Appearance.px(560),
            Appearance.px(560))
        height: Math.min(screen?.height * 0.82 ?? Appearance.px(640),
            Appearance.px(640))
        minimumWidth: Appearance.px(430)
        minimumHeight: Appearance.px(400)

        ClipboardPanel {
            anchors.fill: parent
            visible: clipboardWindow.visible
            onCloseRequested: clipboardWindow.closeWindow()
        }

        Shortcut {
            sequence: "Escape"
            enabled: clipboardWindow.visible
            onActivated: clipboardWindow.closeWindow()
        }

        IpcHandler {
            target: "clipboard"

            function open(): void {
                clipboardWindow.openWindow();
            }

            function close(): void {
                clipboardWindow.closeWindow();
            }

            function toggle(): void {
                clipboardWindow.toggleWindow();
            }

            function visible(): bool {
                return clipboardWindow.visible;
            }
        }
    }

    ManagedWindow {
        id: systemMonitorWindow

        title: "QuickShell " + I18n.tr("systemMonitor")
        width: Math.min(screen?.width * 0.88 ?? Appearance.px(900),
            Appearance.px(900))
        height: Math.min(screen?.height * 0.9 ?? Appearance.px(780),
            Appearance.px(780))
        minimumWidth: Appearance.px(720)
        minimumHeight: Appearance.px(560)

        ResourcePanel {
            anchors.fill: parent
            active: systemMonitorWindow.visible
            onCloseRequested: systemMonitorWindow.closeWindow()
        }

        Shortcut {
            sequence: "Escape"
            enabled: systemMonitorWindow.visible
            onActivated: systemMonitorWindow.closeWindow()
        }

        IpcHandler {
            target: "systemMonitor"

            function open(): void {
                systemMonitorWindow.openWindow();
            }

            function close(): void {
                systemMonitorWindow.closeWindow();
            }

            function toggle(): void {
                systemMonitorWindow.toggleWindow();
            }

            function visible(): bool {
                return systemMonitorWindow.visible;
            }
        }
    }
}
