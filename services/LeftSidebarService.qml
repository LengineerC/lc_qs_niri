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

    function showOnOutput(outputName: string): void {
        if (outputName.length === 0)
            return;

        root.targetOutputName = outputName;
        root.shown = true;
    }

    function toggleOnOutput(outputName: string): void {
        if (outputName.length === 0)
            return;

        if (root.shown
                && root.targetOutputName === outputName) {
            root.close();
            return;
        }

        root.targetOutputName = outputName;
        root.shown = true;
    }

    function requestFocusedOutput(action: string): void {
        root.pendingAction = action;

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
        root.pendingAction = "";
        root.shown = false;
    }

    function toggle(): void {
        root.requestFocusedOutput("toggle");
    }

    function handleFocusedOutputResult(outputText): void {
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

        stdout: StdioCollector {
            onStreamFinished: {
                root.handleFocusedOutputResult(
                    this.text
                );
            }
        }

        stderr: StdioCollector {
            id: focusedOutputError
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                return;

            root.pendingAction = "";

            console.warn(
                "Failed to query niri focused output:",
                exitCode,
                exitStatus,
                focusedOutputError.text
            );
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