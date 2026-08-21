pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    id: root

    readonly property string pamDirectory:
        String(Qt.resolvedUrl("pam")).replace(/^file:\/\//, "")

    PersistentProperties {
        id: runtimeState
        reloadableId: "lock-startup-runtime"
        property bool startupLockChecked: false
    }

    function checkStartupLock() {
        if (runtimeState.startupLockChecked || !ShellSettings.ready)
            return;

        runtimeState.startupLockChecked = true;
        if (ShellSettings.lockOnStartup)
            Qt.callLater(root.open);
    }

    function open() {
        if (sessionLock.locked)
            return;

        authContext.currentText = "";
        authContext.unlockInProgress = false;
        authContext.showFailure = false;
        sessionLock.locked = true;
        LockService.locked = true;
    }

    Connections {
        target: LockService

        function onLockRequested() {
            root.open();
        }
    }

    Connections {
        target: ShellSettings

        function onReadyChanged() {
            root.checkStartupLock();
        }
    }

    Component.onCompleted: checkStartupLock()

    Scope {
        id: authContext

        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false

        signal unlockFailed

        function tryUnlock() {
            if (!currentText || unlockInProgress)
                return;

            unlockInProgress = true;
            showFailure = false;
            pam.start();
        }

        function finishUnlock() {
            if (!sessionLock.locked)
                return;

            sessionLock.locked = false;
            LockService.locked = false;
            currentText = "";
            unlockInProgress = false;
            showFailure = false;
        }

        PamContext {
            id: pam

            configDirectory: root.pamDirectory
            config: "password.conf"

            onPamMessage: {
                if (this.responseRequired)
                    this.respond(authContext.currentText);
            }

            onCompleted: result => {
                if (result === PamResult.Success) {
                    authContext.currentText = "";
                    authContext.showFailure = false;
                    sessionLock.beginUnlock();
                } else {
                    authContext.currentText = "";
                    authContext.showFailure = true;
                    authContext.unlockFailed();
                }
                authContext.unlockInProgress = false;
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        signal beginUnlock

        LockSurface {
            lock: sessionLock
            context: authContext
        }
    }
}
