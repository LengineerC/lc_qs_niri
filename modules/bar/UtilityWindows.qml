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
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            z: -100
            color: ShellSettings.barFrostedGlass
                ? Appearance.withAlpha(
                    Appearance.barGlassBaseColor, 0.66)
                : Appearance.layer2
            border.width: 1
            border.color: ShellSettings.barFrostedGlass
                ? Appearance.barLayer0Border
                : Appearance.layer0Border

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.spatialDuration
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Appearance.spatialDuration
                }
            }
        }

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
            useBarPalette: ShellSettings.barFrostedGlass
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
            useBarPalette: ShellSettings.barFrostedGlass
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
