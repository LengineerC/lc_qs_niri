pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
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
    property var pendingPersistentOutput: null
    property var persistentOutputs: ({})
    property bool persistenceDirectoryReady: false
    property bool persistenceStateReady: false
    property bool persistenceWritePending: false

    readonly property bool persistenceReady:
        persistenceDirectoryReady && persistenceStateReady
    readonly property string niriConfigDirectory:
        stripFileProtocol(StandardPaths.standardLocations(
            StandardPaths.ConfigLocation)[0])
            + "/niri/lc_qs_niri"
    readonly property string persistentConfigFile:
        niriConfigDirectory + "/outputs.kdl"
    readonly property string persistentStateFile:
        ShellSettings.stateDirectory + "/outputs.json"

    readonly property int enabledCount:
        outputs.filter(output => output.enabled).length

    signal applyFinished(bool success, string message)

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function stripFileProtocol(path) {
        return String(path || "").replace(/^file:\/\//, "");
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

    function stableOutputName(output) {
        const make = String(output?.make || "").trim();
        const model = String(output?.model || "").trim();
        const serial = String(output?.serial || "").trim();
        if (make && model && serial)
            return make + " " + model + " " + serial;
        return String(output?.name || "").trim();
    }

    function allowedMaxBpc(value) {
        const number = Math.round(Number(value) || 8);
        return [6, 8, 10, 12, 14, 16].includes(number)
            ? number : 8;
    }

    function outputRecord(output, enabled = undefined,
            mode = undefined, scale = undefined,
            transform = undefined, automaticPosition = undefined,
            x = undefined, y = undefined, vrrEnabled = undefined,
            maxBpc = undefined) {
        return {
            name: String(output.name),
            matchName: stableOutputName(output),
            make: String(output.make || ""),
            model: String(output.model || ""),
            serial: String(output.serial || ""),
            enabled: enabled === undefined
                ? Boolean(output.enabled) : Boolean(enabled),
            mode: String(mode === undefined
                ? output.currentMode : mode || "auto"),
            scale: clampedScale(scale === undefined
                ? output.scale : scale),
            transform: normalizeTransform(transform === undefined
                ? output.transform : transform),
            automaticPosition: automaticPosition === undefined
                ? !output.enabled : Boolean(automaticPosition),
            x: Math.round(Number(x === undefined ? output.x : x) || 0),
            y: Math.round(Number(y === undefined ? output.y : y) || 0),
            vrrEnabled: vrrEnabled === undefined
                ? Boolean(output.vrrEnabled) : Boolean(vrrEnabled),
            maxBpc: allowedMaxBpc(maxBpc === undefined
                ? output.maxBpc : maxBpc)
        };
    }

    function escapeKdlString(value) {
        return String(value || "")
            .replace(/\\/g, "\\\\")
            .replace(/"/g, "\\\"");
    }

    function formatConfigNumber(value) {
        const number = Number(value);
        if (!Number.isFinite(number))
            return "1";
        return Number(number.toFixed(4)).toString();
    }

    function serializeOutput(record) {
        const lines = [
            "output \"" + escapeKdlString(
                record.matchName || record.name) + "\" {"
        ];
        if (!record.enabled)
            lines.push("    off");
        if (record.mode && record.mode !== "auto")
            lines.push("    mode \""
                + escapeKdlString(record.mode) + "\"");
        lines.push("    scale "
            + formatConfigNumber(record.scale));
        lines.push("    transform \""
            + escapeKdlString(normalizeTransform(
                record.transform)) + "\"");
        if (!record.automaticPosition) {
            lines.push("    position x="
                + Math.round(Number(record.x) || 0)
                + " y=" + Math.round(Number(record.y) || 0));
        }
        if (record.vrrEnabled)
            lines.push("    variable-refresh-rate");
        lines.push("    max-bpc "
            + allowedMaxBpc(record.maxBpc));
        lines.push("}");
        return lines.join("\n");
    }

    function persistentRecords() {
        return Object.keys(persistentOutputs)
            .map(key => persistentOutputs[key])
            .filter(record => record && record.name)
            .sort((first, second) =>
                String(first.matchName || first.name).localeCompare(
                    String(second.matchName || second.name)));
    }

    function writePersistentFiles() {
        if (!persistenceReady) {
            persistenceWritePending = true;
            return;
        }

        persistenceWritePending = false;
        const records = persistentRecords();
        const configText = [
            "// Auto-generated by QuickShell display settings.",
            "// Changes made here can be overwritten from the settings window.",
            ""
        ].concat(records.map(record =>
            serializeOutput(record) + "\n")).join("\n");
        persistentConfigStorage.setText(configText);
        persistentStateStorage.setText(JSON.stringify({
            version: 1,
            outputs: records
        }, null, 2));
    }

    function seedPersistentOutputs() {
        const next = Object.assign({}, persistentOutputs);
        for (const output of outputs) {
            if (!output?.name || next[output.name])
                continue;
            const record = outputRecord(output);
            const duplicateKey = Object.keys(next).find(key =>
                next[key]?.matchName === record.matchName);
            if (!duplicateKey)
                next[record.name] = record;
        }
        persistentOutputs = next;
    }

    function persistOutput(record) {
        if (!record)
            return;

        seedPersistentOutputs();
        const next = Object.assign({}, persistentOutputs);
        for (const key of Object.keys(next)) {
            if (key === record.name
                    || next[key]?.matchName === record.matchName)
                delete next[key];
        }
        next[record.name] = record;
        persistentOutputs = next;
        writePersistentFiles();
    }

    function loadPersistentState(text) {
        try {
            const payload = JSON.parse(String(text));
            const records = Array.isArray(payload)
                ? payload : payload.outputs;
            if (!Array.isArray(records))
                throw new Error("Invalid output state");
            const restored = {};
            for (const record of records) {
                if (!record?.name)
                    continue;
                restored[String(record.name)] = {
                    name: String(record.name),
                    matchName: String(record.matchName
                        || record.name),
                    make: String(record.make || ""),
                    model: String(record.model || ""),
                    serial: String(record.serial || ""),
                    enabled: Boolean(record.enabled),
                    mode: String(record.mode || "auto"),
                    scale: clampedScale(record.scale),
                    transform: normalizeTransform(
                        record.transform),
                    automaticPosition:
                        Boolean(record.automaticPosition),
                    x: Math.round(Number(record.x) || 0),
                    y: Math.round(Number(record.y) || 0),
                    vrrEnabled: Boolean(record.vrrEnabled),
                    maxBpc: allowedMaxBpc(record.maxBpc)
                };
            }
            persistentOutputs = restored;
        } catch (error) {
            console.warn(
                "OutputService: cannot parse persistent state:",
                error);
            persistentOutputs = ({});
        }
        persistenceStateReady = true;
        if (persistenceWritePending)
            writePersistentFiles();
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
        pendingPersistentOutput = outputRecord(
            current, enabled, mode, scale, transform,
            automaticPosition, x, y, vrrEnabled, maxBpc);

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
            persistOutput(pendingPersistentOutput);
            pendingPersistentOutput = null;
            applyFinished(true, "");
            applyRefreshTimer.restart();
            return;
        }

        commandProcess.errorOutput = "";
        commandProcess.command = commandQueue.shift();
        commandProcess.running = true;
    }

    Component.onCompleted: {
        persistenceDirectoryProcess.running = true;
        refresh();
    }

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
                root.pendingPersistentOutput = null;
                root.errorMessage = commandProcess.errorOutput
                    || I18n.tr("displayApplyFailed");
                root.applyFinished(false, root.errorMessage);
                root.refresh();
                return;
            }
            root.runNextCommand();
        }
    }

    Process {
        id: persistenceDirectoryProcess

        command: [
            "mkdir", "-p",
            root.niriConfigDirectory,
            ShellSettings.stateDirectory
        ]
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.errorMessage =
                    I18n.tr("displayPersistenceFailed");
                return;
            }
            root.persistenceDirectoryReady = true;
            Qt.callLater(() =>
                persistentStateStorage.reload());
        }
    }

    FileView {
        id: persistentStateStorage

        path: root.persistentStateFile
        printErrors: false

        onLoaded: {
            if (root.persistenceDirectoryReady)
                root.loadPersistentState(text());
        }
        onLoadFailed: error => {
            if (!root.persistenceDirectoryReady)
                return;
            root.persistentOutputs = ({});
            root.persistenceStateReady = true;
            if (root.persistenceWritePending)
                root.writePersistentFiles();
        }
    }

    FileView {
        id: persistentConfigStorage

        path: root.persistentConfigFile
        printErrors: false
    }

    IpcHandler {
        target: "outputs"

        function saveCurrent(): void {
            root.seedPersistentOutputs();
            root.writePersistentFiles();
        }

        function configPath(): string {
            return root.persistentConfigFile;
        }

        function statePath(): string {
            return root.persistentStateFile;
        }

        function persistentCount(): int {
            return root.persistentRecords().length;
        }
    }
}
