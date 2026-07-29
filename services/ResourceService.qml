pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property real cpuUsage: 0
    property var previousCpuStats: null
    property real memoryTotalKb: 0
    property real memoryAvailableKb: 0
    readonly property real memoryUsedKb:
        Math.max(0, memoryTotalKb - memoryAvailableKb)
    readonly property real memoryUsage:
        memoryTotalKb > 0 ? memoryUsedKb / memoryTotalKb : 0
    property real cpuTemperature: 0
    property bool temperatureAvailable: false
    property real cpuFrequencyGhz: 0
    property string cpuModel: I18n.tr("unknown")
    property int logicalCpuCount: 0
    property int currentUid: -1
    property string networkInterface: ""
    property real downloadBytesPerSecond: 0
    property real uploadBytesPerSecond: 0
    property var previousNetworkStats: null

    property var processes: []
    property int activeViewerCount: 0
    property bool processRefreshing: false
    property bool refreshProcessesAgain: false
    property string processError: ""
    property string actionMessage: ""

    readonly property int updateInterval: 2000

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function clamp(value, minimum = 0, maximum = 1) {
        return Math.max(minimum, Math.min(maximum, Number(value) || 0));
    }

    function formatBytesFromKb(kilobytes, decimals = 1) {
        const value = Number(kilobytes) || 0;
        if (value >= 1024 * 1024)
            return (value / (1024 * 1024)).toFixed(decimals) + " GB";
        if (value >= 1024)
            return (value / 1024).toFixed(decimals) + " MB";
        return Math.round(value) + " KB";
    }

    function formatRate(bytesPerSecond) {
        const value = Math.max(0, Number(bytesPerSecond) || 0);
        if (value >= 1024 * 1024 * 1024)
            return (value / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
        if (value >= 1024 * 1024)
            return (value / (1024 * 1024)).toFixed(1) + " MB/s";
        if (value >= 1024)
            return (value / 1024).toFixed(1) + " KB/s";
        return Math.round(value) + " B/s";
    }

    function parseMemory(text) {
        const total = text.match(/^MemTotal:\s+(\d+)/m);
        const available = text.match(/^MemAvailable:\s+(\d+)/m);
        if (total)
            memoryTotalKb = Number(total[1]);
        if (available)
            memoryAvailableKb = Number(available[1]);
    }

    function parseCpuStats(text) {
        const cpuLine = text.match(/^cpu\s+(.+)$/m);
        if (!cpuLine)
            return;

        const values = cpuLine[1].trim().split(/\s+/)
            .map(value => Number(value));
        if (values.length < 4)
            return;

        const idle = values[3] + (values[4] || 0);
        const total = values.reduce(
            (sum, value) => sum + value, 0);
        if (previousCpuStats) {
            const totalDelta = total - previousCpuStats.total;
            const idleDelta = idle - previousCpuStats.idle;
            if (totalDelta > 0)
                cpuUsage = clamp(1 - idleDelta / totalDelta);
        }
        previousCpuStats = { total: total, idle: idle };
    }

    function parseCpuInfo(text) {
        const model = text.match(/^model name\s*:\s*(.+)$/m);
        if (model)
            cpuModel = model[1].trim();

        const frequencies = [];
        String(text).split("\n").forEach(line => {
            const frequency = line.match(
                /^cpu MHz\s*:\s*([\d.]+)$/);
            if (!frequency)
                return;
            const value = Number(frequency[1]);
            if (Number.isFinite(value) && value > 0)
                frequencies.push(value);
        });
        logicalCpuCount = Math.max(logicalCpuCount, frequencies.length);
        if (frequencies.length > 0) {
            const average = frequencies.reduce(
                (sum, value) => sum + value, 0) / frequencies.length;
            cpuFrequencyGhz = average / 1000;
        }
    }

    function parseRoutes(text) {
        const lines = String(text).trim().split("\n");
        let selectedInterface = "";
        for (let index = 1; index < lines.length; index++) {
            const fields = lines[index].trim().split(/\s+/);
            if (fields.length < 4)
                continue;
            const destination = fields[1];
            const flags = Number.parseInt(fields[3], 16);
            if (destination === "00000000"
                    && Number.isFinite(flags) && (flags & 0x1)) {
                selectedInterface = fields[0];
                break;
            }
        }
        if (networkInterface !== selectedInterface) {
            networkInterface = selectedInterface;
            previousNetworkStats = null;
            downloadBytesPerSecond = 0;
            uploadBytesPerSecond = 0;
        }
    }

    function parseNetworkStats(text) {
        const interfaces = {};
        String(text).split("\n").forEach(line => {
            const separator = line.indexOf(":");
            if (separator < 0)
                return;
            const name = line.slice(0, separator).trim();
            const values = line.slice(separator + 1).trim()
                .split(/\s+/).map(value => Number(value));
            if (!name || name === "lo" || values.length < 9)
                return;
            interfaces[name] = {
                received: values[0],
                transmitted: values[8]
            };
        });

        let selected = networkInterface;
        if (!selected || !interfaces[selected]) {
            const names = Object.keys(interfaces);
            selected = names.length > 0 ? names[0] : "";
        }
        if (!selected || !interfaces[selected]) {
            previousNetworkStats = null;
            downloadBytesPerSecond = 0;
            uploadBytesPerSecond = 0;
            return;
        }

        if (networkInterface !== selected) {
            networkInterface = selected;
            previousNetworkStats = null;
        }

        const current = interfaces[selected];
        const now = Date.now();
        if (previousNetworkStats
                && previousNetworkStats.interfaceName === selected) {
            const seconds = Math.max(0.001,
                (now - previousNetworkStats.timestamp) / 1000);
            const receivedDelta =
                current.received - previousNetworkStats.received;
            const transmittedDelta =
                current.transmitted - previousNetworkStats.transmitted;
            downloadBytesPerSecond = receivedDelta >= 0
                ? receivedDelta / seconds : 0;
            uploadBytesPerSecond = transmittedDelta >= 0
                ? transmittedDelta / seconds : 0;
        }
        previousNetworkStats = {
            interfaceName: selected,
            received: current.received,
            transmitted: current.transmitted,
            timestamp: now
        };
    }

    function temperatureCandidateScore(chipName, label) {
        const chip = String(chipName).toLocaleLowerCase();
        const sensor = String(label).toLocaleLowerCase();
        let score = 100;
        if (chip.includes("k10temp") || chip.includes("coretemp")
                || chip.includes("zenpower"))
            score -= 60;
        if (sensor.includes("tctl")
                || sensor.includes("package id 0"))
            score -= 30;
        else if (sensor.includes("tdie")
                || sensor.includes("cpu"))
            score -= 20;
        if (chip.includes("nvme") || chip.includes("spd")
                || chip.includes("gpu"))
            score += 80;
        return score;
    }

    function parseSensors(text) {
        try {
            const payload = JSON.parse(text);
            const candidates = [];
            Object.keys(payload).forEach(chipName => {
                const chip = payload[chipName];
                if (!chip || typeof chip !== "object")
                    return;
                Object.keys(chip).forEach(label => {
                    const sensor = chip[label];
                    if (!sensor || typeof sensor !== "object")
                        return;
                    Object.keys(sensor).forEach(key => {
                        if (!/^temp\d+_input$/.test(key))
                            return;
                        const value = Number(sensor[key]);
                        if (!Number.isFinite(value)
                                || value < -20 || value > 150)
                            return;
                        candidates.push({
                            value: value,
                            score: temperatureCandidateScore(
                                chipName, label)
                        });
                    });
                });
            });
            candidates.sort((first, second) =>
                first.score - second.score);
            temperatureAvailable = candidates.length > 0;
            if (temperatureAvailable)
                cpuTemperature = candidates[0].value;
        } catch (error) {
            temperatureAvailable = false;
        }
    }

    function parseProcessLine(line) {
        const fields = String(line).split("|");
        if (fields.length < 8)
            return null;

        const pid = Number(fields[0].trim());
        const ppid = Number(fields[1].trim());
        const uid = Number(fields[2].trim());
        const cpu = Number(fields[3].trim());
        const memoryPercent = Number(fields[4].trim());
        const rssKb = Number(fields[5].trim());
        const name = fields[6].trim();
        const command = fields.slice(7).join("|").trim();
        if (!Number.isInteger(pid) || pid <= 0)
            return null;
        if (name === "ps" && command.includes("--delimiter"))
            return null;

        return {
            pid: pid,
            ppid: Number.isInteger(ppid) ? ppid : 0,
            uid: Number.isInteger(uid) ? uid : -1,
            cpu: Number.isFinite(cpu) ? cpu : 0,
            memoryPercent:
                Number.isFinite(memoryPercent) ? memoryPercent : 0,
            rssKb: Number.isFinite(rssKb) ? rssKb : 0,
            name: name || I18n.tr("unknown"),
            command: command || name,
            canSignal: uid === currentUid && pid > 1
        };
    }

    function refreshProcesses() {
        if (activeViewerCount <= 0)
            return;
        if (processListProcess.running) {
            refreshProcessesAgain = true;
            return;
        }
        processListProcess.buffer = [];
        processRefreshing = true;
        processListProcess.running = true;
    }

    function startProcessViewer() {
        activeViewerCount += 1;
        if (activeViewerCount === 1)
            refreshProcesses();
    }

    function stopProcessViewer() {
        activeViewerCount = Math.max(0, activeViewerCount - 1);
    }

    function processByPid(pid) {
        return processes.find(entry => entry.pid === Number(pid));
    }

    function signalProcess(pid, force) {
        const entry = processByPid(pid);
        if (!entry || !entry.canSignal || signalProcessCommand.running)
            return false;

        actionMessage = "";
        signalProcessCommand.targetPid = entry.pid;
        signalProcessCommand.force = Boolean(force);
        signalProcessCommand.command = [
            "kill", force ? "-KILL" : "-TERM",
            "--", String(entry.pid)
        ];
        signalProcessCommand.running = true;
        return true;
    }

    function copyText(text) {
        if (copyProcess.running)
            copyProcess.running = false;
        copyProcess.command = ["wl-copy", "--", String(text)];
        copyProcess.running = true;
    }

    Component.onCompleted: {
        memoryFile.reload();
        statFile.reload();
        cpuInfoFile.reload();
        routeFile.reload();
        networkFile.reload();
        identityProcess.running = true;
        sensorProcess.running = true;
    }

    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: {
            memoryFile.reload();
            statFile.reload();
            cpuInfoFile.reload();
            routeFile.reload();
            networkFile.reload();
            if (!sensorProcess.running)
                sensorProcess.running = true;
        }
    }

    Timer {
        interval: root.updateInterval
        running: root.activeViewerCount > 0
        repeat: true
        onTriggered: root.refreshProcesses()
    }

    Timer {
        id: processRefreshDelay
        interval: 250
        onTriggered: root.refreshProcesses()
    }

    Timer {
        id: actionMessageTimer
        interval: 2800
        onTriggered: root.actionMessage = ""
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: root.parseMemory(text())
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        printErrors: false
        onLoaded: root.parseCpuStats(text())
    }

    FileView {
        id: cpuInfoFile
        path: "/proc/cpuinfo"
        printErrors: false
        onLoaded: root.parseCpuInfo(text())
    }

    FileView {
        id: routeFile
        path: "/proc/net/route"
        printErrors: false
        onLoaded: root.parseRoutes(text())
    }

    FileView {
        id: networkFile
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: root.parseNetworkStats(text())
    }

    Process {
        id: sensorProcess
        command: ["sensors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseSensors(text)
        }
        stderr: StdioCollector {}
    }

    Process {
        id: identityProcess
        command: ["id", "-u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const uid = Number(text.trim());
                if (Number.isInteger(uid))
                    root.currentUid = uid;
            }
        }
    }

    Process {
        id: processListProcess
        property var buffer: []
        command: [
            "ps", "-ww", "--no-headers", "--delimiter", "|",
            "-eo", "pid=,ppid=,uid=,pcpu=,pmem=,rss=,comm=,args=",
            "--sort=-pcpu"
        ]
        stdout: SplitParser {
            onRead: line => {
                const entry = root.parseProcessLine(line);
                if (entry)
                    processListProcess.buffer.push(entry);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.processError = text.trim();
            }
        }
        onExited: exitCode => {
            root.processRefreshing = false;
            if (exitCode === 0) {
                root.processes = processListProcess.buffer;
                root.processError = "";
            } else if (!root.processError) {
                root.processError = I18n.tr("processReadFailed");
            }
            if (root.refreshProcessesAgain) {
                root.refreshProcessesAgain = false;
                Qt.callLater(() => root.refreshProcesses());
            }
        }
    }

    Process {
        id: signalProcessCommand
        property int targetPid: 0
        property bool force: false
        property string errorOutput: ""
        stderr: StdioCollector {
            onStreamFinished:
                signalProcessCommand.errorOutput = text.trim()
        }
        onStarted: errorOutput = ""
        onExited: exitCode => {
            if (exitCode === 0) {
                root.actionMessage = force
                    ? I18n.tr("processForceStopped")
                    : I18n.tr("processStopped");
            } else {
                root.actionMessage = errorOutput
                    || I18n.tr("processSignalFailed");
            }
            actionMessageTimer.restart();
            processRefreshDelay.restart();
        }
    }

    Process {
        id: copyProcess
    }
}
