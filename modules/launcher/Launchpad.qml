pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    id: root

    property bool shown: false
    property string targetOutputName: ""
    property string pendingAction: ""
    property int requestRevision: 0
    property int activeRequestRevision: -1

    Component.onDestruction: NiriService.launchpadProgress = 0

    onTargetOutputNameChanged: {
        // A launchpad moved to another output starts a fresh reveal there.
        NiriService.launchpadProgress = 0;
    }

    function cancelFocusedOutputRequest() {
        ++requestRevision;
        pendingAction = "";
    }

    function showOnOutput(outputName) {
        if (!outputName)
            return;
        cancelFocusedOutputRequest();
        targetOutputName = outputName;
        shown = true;
    }

    function toggleOnOutput(outputName) {
        if (!outputName)
            return;
        cancelFocusedOutputRequest();
        if (shown && targetOutputName === outputName) {
            close();
            return;
        }
        targetOutputName = outputName;
        shown = true;
    }

    function requestFocusedOutput(action) {
        ++requestRevision;
        pendingAction = action;
        if (!focusedOutputProcess.running)
            startFocusedOutputRequest();
    }

    function startFocusedOutputRequest() {
        if (!pendingAction || focusedOutputProcess.running)
            return;
        activeRequestRevision = requestRevision;
        focusedOutputProcess.output = "";
        focusedOutputProcess.exec([
            "niri", "msg", "--json", "focused-output"
        ]);
    }

    function open() {
        requestFocusedOutput("open");
    }

    function close() {
        cancelFocusedOutputRequest();
        shown = false;
    }

    function toggle() {
        requestFocusedOutput("toggle");
    }

    function handleFocusedOutputResult(outputText, completedRevision) {
        if (completedRevision !== requestRevision
                || completedRevision !== activeRequestRevision) {
            return;
        }

        const action = pendingAction;
        pendingAction = "";
        if (!action)
            return;

        try {
            const output = JSON.parse(String(outputText ?? "").trim());
            const outputName = String(output?.name ?? "");
            if (!outputName) {
                console.warn("Launchpad: focused output has no name");
                return;
            }
            if (action === "open")
                showOnOutput(outputName);
            else if (action === "toggle")
                toggleOnOutput(outputName);
        } catch (error) {
            console.warn("Launchpad: cannot parse focused output:",
                outputText, error);
        }
    }

    Process {
        id: focusedOutputProcess

        property string output: ""

        stdout: StdioCollector {
            onStreamFinished:
                focusedOutputProcess.output = text
        }

        stderr: StdioCollector {
            id: focusedOutputError
        }

        onExited: (exitCode, exitStatus) => {
            const completedRevision = root.activeRequestRevision;
            if (exitCode === 0) {
                root.handleFocusedOutputResult(
                    focusedOutputProcess.output, completedRevision);
            } else {
                if (completedRevision === root.requestRevision)
                    root.pendingAction = "";
                console.warn("Launchpad: focused-output failed:",
                    exitCode, exitStatus, focusedOutputError.text);
            }

            root.activeRequestRevision = -1;
            if (root.pendingAction)
                Qt.callLater(root.startFocusedOutputRequest);
        }
    }

    IpcHandler {
        target: "launcher"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }

        function visible(): bool {
            return root.shown;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: launchpadWindow

            required property ShellScreen modelData
            property real revealProgress: 0
            readonly property bool targetShown: root.shown
                && root.targetOutputName === modelData.name

            screen: modelData
            visible: targetShown || revealProgress > 0.001
            color: "transparent"
            exclusiveZone: -1
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace:
                ShellSettings.launchpadBackgroundMode === "window"
                    ? "quickshell:launchpad-window-blur"
                    : "quickshell:launchpad-wallpaper"
            WlrLayershell.keyboardFocus: targetShown
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onTargetShownChanged: {
                revealAnimation.stop();
                revealAnimation.from = revealProgress;
                revealAnimation.to = targetShown ? 1 : 0;
                revealAnimation.duration = targetShown
                    ? Math.max(180, Appearance.spatialDuration)
                    : Math.max(130, Appearance.fastDuration);
                revealAnimation.easing.type = targetShown
                    ? Easing.OutCubic : Easing.InCubic;
                revealAnimation.start();
            }

            onRevealProgressChanged: {
                if (root.targetOutputName === modelData.name)
                    NiriService.launchpadProgress = revealProgress;
            }

            NumberAnimation {
                id: revealAnimation

                target: launchpadWindow
                property: "revealProgress"
            }

            Loader {
                anchors.fill: parent
                active: launchpadWindow.visible
                    && ShellSettings.launchpadBackgroundMode === "wallpaper"

                sourceComponent: Component {
                    Item {
                        opacity: launchpadWindow.revealProgress
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blur: 1
                            blurMax: Appearance.px(48)
                            blurMultiplier: 1
                        }

                        Image {
                            anchors.fill: parent
                            source: WallpaperService.fileUrl(
                                WallpaperService.currentPath)
                            sourceSize {
                                width: launchpadWindow.width
                                height: launchpadWindow.height
                            }
                            fillMode: WallpaperService.imageFillMode
                            asynchronous: true
                            cache: false
                            smooth: true
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                opacity: launchpadWindow.revealProgress
                color: Appearance.withAlpha(
                    Theme.palette.m3background,
                    Theme.darkMode ? 0.48 : 0.34)
            }

            MouseArea {
                anchors.fill: parent
                enabled: launchpadWindow.targetShown
                onClicked: root.close()
            }

            Loader {
                anchors.fill: parent
                active: launchpadWindow.visible

                sourceComponent: Component {
                    LaunchpadContent {
                        active: launchpadWindow.targetShown
                        revealProgress: launchpadWindow.revealProgress
                        onCloseRequested: root.close()
                    }
                }
            }
        }
    }
}
