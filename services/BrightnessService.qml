pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property var states: ({})
    property var backlightDevices: []
    property var ddcDevices: ({})
    property bool ddcInstalled: false
    property bool refreshing: false
    property bool refreshAgain: false
    property string pendingOutput: ""
    property int pendingPercent: 0
    property string activeOutput: ""
    property int activePercent: 0

    readonly property string discoveryScript: [
        "if command -v ddcutil >/dev/null 2>&1; then",
        "  printf 'META\\tDDC\\t1\\n'",
        "else",
        "  printf 'META\\tDDC\\t0\\n'",
        "fi",
        "for path in /sys/class/backlight/*; do",
        "  [ -e \"$path\" ] || continue",
        "  name=${path##*/}",
        "  current=$(cat \"$path/brightness\" 2>/dev/null) || continue",
        "  maximum=$(cat \"$path/max_brightness\" 2>/dev/null) || continue",
        "  printf 'BACKLIGHT\\t%s\\t%s\\t%s\\n' \"$name\" \"$current\" \"$maximum\"",
        "done",
        "if command -v ddcutil >/dev/null 2>&1; then",
        "  ddcutil detect --brief 2>/dev/null | awk '",
        "    function emit() {",
        "      if (bus != \"\" && connector != \"\")",
        "        print bus \"\\t\" connector",
        "      bus = \"\"; connector = \"\"",
        "    }",
        "    /^Display [0-9]+/ { emit(); next }",
        "    /I2C bus:/ { bus=$0; sub(/^.*\\/dev\\/i2c-/, \"\", bus); gsub(/[[:space:]]/, \"\", bus) }",
        "    /DRM connector:/ { connector=$0; sub(/^.*DRM connector:[[:space:]]*/, \"\", connector); sub(/^card[0-9]+-/, \"\", connector); gsub(/[[:space:]]/, \"\", connector) }",
        "    END { emit() }' | while IFS='\\t' read -r bus connector; do",
        "      values=$(ddcutil --bus \"$bus\" getvcp 10 2>/dev/null | sed -n 's/.*current value = *\\([0-9][0-9]*\\), max value = *\\([0-9][0-9]*\\).*/\\1 \\2/p' | head -n 1)",
        "      [ -n \"$values\" ] || continue",
        "      set -- $values",
        "      printf 'DDC\\t%s\\t%s\\t%s\\t%s\\n' \"$connector\" \"$bus\" \"$1\" \"$2\"",
        "    done",
        "fi"
    ].join("\n")

    function load(): void {
        refresh();
    }

    function internalOutput(outputName) {
        return /^(eDP|EDP|LVDS|DSI)-/.test(String(outputName));
    }

    function emptyState(outputName) {
        return {
            outputName: String(outputName || ""),
            available: false,
            backend: "",
            device: "",
            value: 0,
            maximum: 100,
            percent: 0,
            setting: false,
            error: "",
            reason: ddcInstalled
                ? I18n.tr("brightnessUnavailable")
                : I18n.tr("brightnessBackendMissing")
        };
    }

    function stateFor(outputName) {
        const snapshot = states;
        return snapshot[String(outputName)] ?? emptyState(outputName);
    }

    function updateState(outputName, changes) {
        const name = String(outputName || "");
        if (!name)
            return;
        const next = Object.assign({}, states);
        next[name] = Object.assign({}, stateFor(name), changes);
        states = next;
    }

    function rebuildStates() {
        const next = {};
        const outputs = OutputService.outputs;
        const internalDevice = backlightDevices[0] ?? null;

        for (const output of outputs) {
            const name = String(output.name || "");
            let state = emptyState(name);
            if (internalOutput(name) && internalDevice) {
                state = {
                    outputName: name,
                    available: true,
                    backend: "backlight",
                    device: internalDevice.name,
                    value: internalDevice.value,
                    maximum: internalDevice.maximum,
                    percent: Math.round(internalDevice.value
                        / Math.max(1, internalDevice.maximum) * 100),
                    setting: states[name]?.setting ?? false,
                    error: "",
                    reason: ""
                };
            } else if (ddcDevices[name]) {
                const device = ddcDevices[name];
                state = {
                    outputName: name,
                    available: true,
                    backend: "ddc",
                    device: device.bus,
                    value: device.value,
                    maximum: device.maximum,
                    percent: Math.round(device.value
                        / Math.max(1, device.maximum) * 100),
                    setting: states[name]?.setting ?? false,
                    error: "",
                    reason: ""
                };
            }
            next[name] = state;
        }
        states = next;
    }

    function parseDiscovery(output) {
        const backlights = [];
        const ddc = {};
        let hasDdc = false;
        const lines = String(output || "").split("\n");
        for (const line of lines) {
            const fields = line.split("\t");
            if (fields[0] === "META" && fields[1] === "DDC") {
                hasDdc = fields[2] === "1";
            } else if (fields[0] === "BACKLIGHT"
                    && fields.length >= 4) {
                backlights.push({
                    name: fields[1],
                    value: Number(fields[2]),
                    maximum: Math.max(1, Number(fields[3]))
                });
            } else if (fields[0] === "DDC" && fields.length >= 5) {
                ddc[fields[1]] = {
                    bus: fields[2],
                    value: Number(fields[3]),
                    maximum: Math.max(1, Number(fields[4]))
                };
            }
        }
        backlightDevices = backlights;
        ddcDevices = ddc;
        ddcInstalled = hasDdc;
        rebuildStates();
    }

    function refresh() {
        if (discoveryProcess.running) {
            refreshAgain = true;
            return;
        }
        refreshing = true;
        discoveryProcess.output = "";
        discoveryProcess.running = true;
    }

    function setBrightness(outputName, percent) {
        const state = stateFor(outputName);
        if (!state.available)
            return;
        const clamped = Math.max(1, Math.min(100,
            Math.round(Number(percent) || 1)));
        pendingOutput = String(outputName);
        pendingPercent = clamped;
        updateState(outputName, {
            percent: clamped,
            setting: true,
            error: ""
        });
        applyTimer.restart();
    }

    function applyPending() {
        if (setProcess.running || !pendingOutput)
            return;
        const outputName = pendingOutput;
        const percent = pendingPercent;
        const state = stateFor(outputName);
        pendingOutput = "";
        if (!state.available) {
            updateState(outputName, { setting: false });
            return;
        }

        activeOutput = outputName;
        activePercent = percent;
        if (state.backend === "backlight") {
            const raw = Math.max(1, Math.round(
                state.maximum * percent / 100));
            setProcess.command = [
                "busctl", "call",
                "org.freedesktop.login1",
                "/org/freedesktop/login1/session/auto",
                "org.freedesktop.login1.Session",
                "SetBrightness", "ssu",
                "backlight", state.device, String(raw)
            ];
        } else {
            const raw = Math.round(state.maximum * percent / 100);
            setProcess.command = [
                "ddcutil", "--bus", state.device,
                "setvcp", "10", String(raw)
            ];
        }
        setProcess.running = true;
    }

    Connections {
        target: OutputService
        function onOutputsChanged() {
            root.rebuildStates();
        }
    }

    Timer {
        id: applyTimer
        interval: 55
        repeat: false
        onTriggered: root.applyPending()
    }

    Timer {
        id: refreshAfterSetTimer
        interval: 220
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: discoveryProcess
        property string output: ""
        command: ["sh", "-c", root.discoveryScript]
        stdout: StdioCollector {
            onStreamFinished: discoveryProcess.output = text
        }
        onExited: exitCode => {
            root.refreshing = false;
            if (exitCode === 0)
                root.parseDiscovery(output);
            if (root.refreshAgain) {
                root.refreshAgain = false;
                Qt.callLater(() => root.refresh());
            }
        }
    }

    Process {
        id: setProcess
        property string errorOutput: ""
        stderr: StdioCollector {
            onStreamFinished: setProcess.errorOutput = text.trim()
        }
        onExited: exitCode => {
            const outputName = root.activeOutput;
            const newerForSameOutput = root.pendingOutput === outputName;
            root.updateState(outputName, {
                percent: newerForSameOutput
                    ? root.pendingPercent : root.activePercent,
                setting: newerForSameOutput,
                error: exitCode === 0 ? ""
                    : (setProcess.errorOutput
                        || I18n.tr("brightnessSetFailed"))
            });
            root.activeOutput = "";
            if (root.pendingOutput)
                applyTimer.restart();
            else if (exitCode === 0)
                refreshAfterSetTimer.restart();
        }
    }

    IpcHandler {
        target: "brightness"

        function status(outputName: string): string {
            return JSON.stringify(root.stateFor(outputName));
        }

        function refresh(): void {
            root.refresh();
        }

        function set(outputName: string, percent: int): void {
            root.setBrightness(outputName, percent);
        }
    }
}
