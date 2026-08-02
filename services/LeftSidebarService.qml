pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool shown: false

    property string targetOutputName: ""

    property string pendingAction: ""
    property int requestRevision: 0
    property int activeRequestRevision: -1

    function load(): void {
        // Forces singleton construction from shell.qml.
    }

    function cancelFocusedOutputRequest(): void {
        ++root.requestRevision;
        root.pendingAction = "";
    }

    function showOnOutput(outputName: string): void {
        if (outputName.length === 0)
            return;

        root.cancelFocusedOutputRequest();
        root.targetOutputName = outputName;
        root.shown = true;
    }

    function toggleOnOutput(outputName: string): void {
        if (outputName.length === 0)
            return;

        root.cancelFocusedOutputRequest();
        if (root.shown
                && root.targetOutputName === outputName) {
            root.close();
            return;
        }

        root.targetOutputName = outputName;
        root.shown = true;
    }

    function requestFocusedOutput(action: string): void {
        ++root.requestRevision;
        root.pendingAction = action;

        if (focusedOutputProcess.running)
            return;

        root.startFocusedOutputRequest();
    }

    function startFocusedOutputRequest(): void {
        if (root.pendingAction.length === 0
                || focusedOutputProcess.running) {
            return;
        }

        root.activeRequestRevision = root.requestRevision;
        focusedOutputProcess.output = "";
        focusedOutputProcess.exec([
            "niri",
            "msg",
            "--json",
            "focused-output"
        ]);
    }

    function open(): void {
        root.requestFocusedOutput("open");
    }

    function close(): void {
        /*
         * 防止查询仍在执行时，查询结果又把侧边栏打开。
         */
        root.cancelFocusedOutputRequest();
        root.shown = false;
    }

    function toggle(): void {
        root.requestFocusedOutput("toggle");
    }

    function handleFocusedOutputResult(
            outputText: string, completedRevision: int): void {
        if (completedRevision !== root.requestRevision
                || completedRevision !== root.activeRequestRevision) {
            return;
        }

        const action = root.pendingAction;
        root.pendingAction = "";

        /*
         * close() 已经取消了待执行操作。
         */
        if (action.length === 0)
            return;

        let outputName = "";

        try {
            const output = JSON.parse(
                String(outputText ?? "").trim()
            );

            outputName = String(output?.name ?? "");
        } catch (error) {
            console.warn(
                "Failed to parse niri focused output:",
                outputText,
                error
            );

            return;
        }

        if (outputName.length === 0) {
            console.warn(
                "Niri focused output has no name:",
                outputText
            );

            return;
        }

        switch (action) {
        case "open":
            root.showOnOutput(outputName);
            break;

        case "toggle":
            root.toggleOnOutput(outputName);
            break;
        }
    }

    Process {
        id: focusedOutputProcess

        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: {
                focusedOutputProcess.output = this.text;
            }
        }

        stderr: StdioCollector {
            id: focusedOutputError
        }

        onExited: (exitCode, exitStatus) => {
            const completedRevision = root.activeRequestRevision;

            if (exitCode === 0) {
                root.handleFocusedOutputResult(
                    focusedOutputProcess.output,
                    completedRevision
                );
            } else {
                if (completedRevision === root.requestRevision)
                    root.pendingAction = "";

                console.warn(
                    "Failed to query niri focused output:",
                    exitCode,
                    exitStatus,
                    focusedOutputError.text
                );
            }

            root.activeRequestRevision = -1;

            if (root.pendingAction.length > 0)
                Qt.callLater(() => root.startFocusedOutputRequest());
        }
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

        function isOpen(): bool {
            return root.shown;
        }

        function targetOutput(): string {
            return root.targetOutputName;
        }
    }
}
