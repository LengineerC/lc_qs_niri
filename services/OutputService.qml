pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property var outputs: []
    property bool refreshing: false
    property bool applying: false
    property string errorMessage: ""
    property var commandQueue: []
    property string operationOutput: ""
    property bool refreshAgain: false

    readonly property int enabledCount:
        outputs.filter(output => output.enabled).length

    signal applyFinished(bool success, string message)

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function refresh() {
        if (refreshProcess.running) {
            refreshAgain = true;
            return;
        }
        refreshing = true;
        refreshProcess.output = "";
        refreshProcess.running = true;
    }

    function normalizeTransform(transform) {
        const value = String(transform || "normal")
            .toLowerCase().replace(/[_-]/g, "");
        switch (value) {
        case "90":
            return "90";
        case "180":
            return "180";
        case "270":
            return "270";
        case "flipped":
            return "flipped";
        case "flipped90":
            return "flipped-90";
        case "flipped180":
            return "flipped-180";
        case "flipped270":
            return "flipped-270";
        default:
            return "normal";
        }
    }

    function refreshText(refreshRate) {
        return (Number(refreshRate) / 1000).toFixed(3);
    }

    function modeValue(mode) {
        return mode.width + "x" + mode.height
            + "@" + refreshText(mode.refresh_rate);
    }

    function modeLabel(mode) {
        const rate = Number(refreshText(mode.refresh_rate))
            .toFixed(Number(mode.refresh_rate) % 1000 === 0 ? 0 : 2);
        return mode.width + " × " + mode.height + "  " + rate + " Hz"
            + (mode.is_preferred ? "  ★" : "");
    }

    function normalizeOutput(output) {
        const modes = (output.modes || []).map(mode => ({
            width: Number(mode.width),
            height: Number(mode.height),
            refreshRate: Number(mode.refresh_rate),
            preferred: Boolean(mode.is_preferred),
            value: modeValue(mode),
            label: modeLabel(mode)
        }));
        const currentIndex = output.current_mode === null
                || output.current_mode === undefined
            ? -1 : Number(output.current_mode);
        const currentMode = currentIndex >= 0
                && currentIndex < modes.length
            ? modes[currentIndex]
            : modes.find(mode => mode.preferred) || modes[0] || {
                value: "auto",
                label: "Auto"
            };
        const logical = output.logical;

        return {
            name: String(output.name || ""),
            make: String(output.make || ""),
            model: String(output.model || ""),
            serial: String(output.serial || ""),
            physicalWidth: Number(output.physical_size?.[0] || 0),
            physicalHeight: Number(output.physical_size?.[1] || 0),
            modes: modes,
            currentMode: currentMode.value,
            enabled: logical !== null && logical !== undefined,
            x: Math.round(Number(logical?.x || 0)),
            y: Math.round(Number(logical?.y || 0)),
            logicalWidth: Math.round(Number(logical?.width || 0)),
            logicalHeight: Math.round(Number(logical?.height || 0)),
            scale: Number(logical?.scale || 1),
            transform: normalizeTransform(logical?.transform),
            vrrSupported: Boolean(output.vrr_supported),
            vrrEnabled: Boolean(output.vrr_enabled),
            maxBpc: Number(output.max_bpc || 8)
        };
    }

    function parseOutputs(text) {
        try {
            const payload = JSON.parse(text);
            outputs = Object.keys(payload)
                .map(name => normalizeOutput(payload[name]))
                .sort((first, second) => {
                    if (first.enabled !== second.enabled)
                        return first.enabled ? -1 : 1;
                    return first.name.localeCompare(second.name);
                });
            errorMessage = "";
        } catch (error) {
            errorMessage = I18n.tr("displayReadFailed")
                + ": " + error;
            console.warn("OutputService: cannot parse outputs:", error);
        }
    }

    function clampedScale(value) {
        return Math.max(0.5, Math.min(4, Number(value) || 1));
    }

    function applyOutput(name, enabled, mode, scale,
            transform, automaticPosition, x, y, vrrEnabled, maxBpc) {
        const current = outputs.find(output => output.name === name);
        if (!current || applying)
            return;

        if (!enabled && current.enabled && enabledCount <= 1) {
            errorMessage = I18n.tr("cannotDisableLastOutput");
            applyFinished(false, errorMessage);
            return;
        }

        errorMessage = "";
        operationOutput = name;
        commandQueue = [];

        if (!enabled) {
            commandQueue.push(["niri", "msg", "output", name, "off"]);
        } else {
            if (!current.enabled)
                commandQueue.push(["niri", "msg", "output", name, "on"]);

            commandQueue.push([
                "niri", "msg", "output", name, "mode",
                String(mode || "auto")
            ]);
            commandQueue.push([
                "niri", "msg", "output", name, "scale",
                String(clampedScale(scale))
            ]);
            commandQueue.push([
                "niri", "msg", "output", name, "transform",
                normalizeTransform(transform)
            ]);
            if (automaticPosition) {
                commandQueue.push([
                    "niri", "msg", "output", name,
                    "position", "auto"
                ]);
            } else {
                commandQueue.push([
                    "niri", "msg", "output", name,
                    "position", "set",
                    String(Math.round(Number(x) || 0)),
                    String(Math.round(Number(y) || 0))
                ]);
            }
            if (current.vrrSupported) {
                commandQueue.push([
                    "niri", "msg", "output", name, "vrr",
                    vrrEnabled ? "on" : "off"
                ]);
            }
            commandQueue.push([
                "niri", "msg", "output", name, "max-bpc",
                String(maxBpc)
            ]);
        }

        applying = true;
        runNextCommand();
    }

    function runNextCommand() {
        if (commandQueue.length === 0) {
            applying = false;
            applyFinished(true, "");
            applyRefreshTimer.restart();
            return;
        }

        commandProcess.errorOutput = "";
        commandProcess.command = commandQueue.shift();
        commandProcess.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        id: applyRefreshTimer

        interval: 180
        onTriggered: root.refresh()
    }

    Process {
        id: refreshProcess

        property string output: ""
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: refreshProcess.output = text
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.errorMessage = text.trim();
            }
        }
        onExited: exitCode => {
            root.refreshing = false;
            if (exitCode === 0)
                root.parseOutputs(output);
            else if (!root.errorMessage)
                root.errorMessage = I18n.tr("displayReadFailed");

            if (root.refreshAgain) {
                root.refreshAgain = false;
                Qt.callLater(() => root.refresh());
            }
        }
    }

    Process {
        id: commandProcess

        property string errorOutput: ""
        stderr: StdioCollector {
            onStreamFinished: commandProcess.errorOutput = text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.commandQueue = [];
                root.applying = false;
                root.errorMessage = commandProcess.errorOutput
                    || I18n.tr("displayApplyFailed");
                root.applyFinished(false, root.errorMessage);
                root.refresh();
                return;
            }
            root.runNextCommand();
        }
    }
}
