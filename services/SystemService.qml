pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.common

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: false
    property string activeWifiSsid: ""
    property int wifiStrength: 0
    property var wifiNetworks: []
    property var savedWifiSsids: []
    property string passwordRequestedSsid: ""
    property string wifiConnectTargetSsid: ""
    property string statusMessage: ""

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property bool bluetoothEnabled:
        bluetoothAdapter?.enabled ?? false
    readonly property bool bluetoothDiscovering:
        bluetoothAdapter?.discovering ?? false
    readonly property var bluetoothDevices: Bluetooth.devices.values
    readonly property var connectedBluetoothDevices:
        bluetoothDevices.filter(device => device.connected)
    readonly property string connectedBluetoothName:
        connectedBluetoothDevices[0]?.name ?? ""

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sinkReady: sink?.ready ?? false
    readonly property bool sourceReady: source?.ready ?? false
    readonly property real volume:
        Math.min(1, sink?.audio?.volume ?? 0)
    readonly property real microphoneVolume:
        Math.min(1, source?.audio?.volume ?? 0)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool microphoneMuted: source?.audio?.muted ?? false
    readonly property string sinkName:
        sink ? (sink.nickname || sink.description || sink.name)
            : I18n.tr("audioOutput")
    readonly property string sourceName:
        source ? (source.nickname || source.description || source.name)
            : I18n.tr("microphone")
    readonly property var outputDevices:
        Pipewire.nodes.values.filter(node =>
            node.audio && node.isSink && !node.isStream).sort((a, b) => {
                if (a === root.sink && b !== root.sink)
                    return -1;
                if (b === root.sink && a !== root.sink)
                    return 1;
                return root.audioDeviceName(a).localeCompare(
                    root.audioDeviceName(b));
            })
    readonly property var inputDevices:
        Pipewire.nodes.values.filter(node =>
            node.audio && !node.isSink && !node.isStream).sort((a, b) => {
                if (a === root.source && b !== root.source)
                    return -1;
                if (b === root.source && a !== root.source)
                    return 1;
                return root.audioDeviceName(a).localeCompare(
                    root.audioDeviceName(b));
            })

    function splitEscaped(line) {
        const fields = [];
        let field = "";
        let escaped = false;
        for (let index = 0; index < line.length; ++index) {
            const character = line[index];
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }
        fields.push(field);
        return fields;
    }

    function wifiIcon(strength = wifiStrength) {
        if (strength >= 80)
            return "󰤨";
        if (strength >= 60)
            return "󰤥";
        if (strength >= 40)
            return "󰤢";
        if (strength >= 20)
            return "󰤟";
        return "󰤯";
    }

    function volumeIcon() {
        if (muted)
            return "󰝟";
        if (volume <= 0.01)
            return "󰕿";
        if (volume < 0.5)
            return "󰖀";
        return "󰕾";
    }

    function microphoneIcon() {
        return microphoneMuted ? "󰍭" : "󰍬";
    }

    function audioDeviceName(node) {
        if (!node)
            return I18n.tr("unknown");
        return node.nickname || node.description || node.name
            || I18n.tr("unknown");
    }

    function refreshWifi(rescan = false) {
        if (wifiListProcess.running)
            return;
        wifiScanning = rescan;
        wifiListProcess.exec([
            "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", rescan ? "yes" : "no"
        ]);
        wifiRadioProcess.running = true;
        savedWifiProcess.running = true;
    }

    function setWifiEnabled(enabled) {
        wifiToggleProcess.exec([
            "nmcli", "radio", "wifi", enabled ? "on" : "off"
        ]);
    }

    function toggleWifi() {
        setWifiEnabled(!wifiEnabled);
    }

    function connectWifi(ssid, password = "") {
        if (!ssid || wifiConnectProcess.running)
            return;

        const network = wifiNetworks.find(item => item.ssid === ssid);
        wifiConnectTargetSsid = ssid;
        if (network?.active) {
            wifiConnectProcess.exec(["nmcli", "connection", "down", "id", ssid]);
            return;
        }

        const saved = savedWifiSsids.includes(ssid);
        if (!saved && network?.secure && !password) {
            passwordRequestedSsid = ssid;
            return;
        }

        passwordRequestedSsid = "";
        wifiConnecting = true;
        statusMessage = "";
        if (saved && password)
            wifiPasswordUpdateProcess.exec([
                "nmcli", "connection", "modify", "id", ssid,
                "802-11-wireless-security.psk", password
            ]);
        else if (saved)
            wifiConnectProcess.exec(["nmcli", "connection", "up", "id", ssid]);
        else if (password)
            wifiConnectProcess.exec([
                "nmcli", "device", "wifi", "connect", ssid,
                "password", password
            ]);
        else
            wifiConnectProcess.exec([
                "nmcli", "device", "wifi", "connect", ssid
            ]);
    }

    function setBluetoothEnabled(enabled) {
        if (!bluetoothAdapter)
            return;
        bluetoothAdapter.enabled = enabled;
        bluetoothAdapter.discovering = enabled;
        if (enabled)
            bluetoothDiscoveryTimer.restart();
        else
            bluetoothDiscoveryTimer.stop();
    }

    function toggleBluetooth() {
        setBluetoothEnabled(!bluetoothEnabled);
    }

    function setBluetoothDiscovering(discovering) {
        if (bluetoothAdapter?.enabled) {
            bluetoothAdapter.discovering = discovering;
            if (discovering)
                bluetoothDiscoveryTimer.restart();
            else
                bluetoothDiscoveryTimer.stop();
        }
    }

    function toggleBluetoothDevice(device) {
        if (!device)
            return;
        if (device.connected) {
            device.disconnect();
        } else if (!device.paired) {
            device.pair();
        } else {
            device.trusted = true;
            device.connect();
        }
    }

    function setVolume(value) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setMicrophoneVolume(value) {
        if (source?.audio)
            source.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicrophoneMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setDefaultOutput(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultInput(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    function load() {
        // Accessing the singleton is enough to construct it. Initial refresh is
        // handled by Component.onCompleted so startup does not launch duplicates.
    }

    Component.onCompleted: refreshWifi(false)

    PwObjectTracker {
        objects: [
            root.sink,
            root.source,
            ...root.outputDevices,
            ...root.inputDevices
        ].filter(node => node)
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshWifi(false)
    }

    Timer {
        id: bluetoothDiscoveryTimer

        interval: 15000
        onTriggered: {
            if (root.bluetoothAdapter)
                root.bluetoothAdapter.discovering = false;
        }
    }

    Process {
        id: wifiRadioProcess
        command: ["nmcli", "-t", "-f", "WIFI", "general"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
                if (!root.wifiEnabled) {
                    root.activeWifiSsid = "";
                    root.wifiStrength = 0;
                    root.wifiNetworks = [];
                }
            }
        }
    }

    Process {
        id: savedWifiProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = [];
                for (const line of text.trim().split("\n")) {
                    const fields = root.splitEscaped(line);
                    if (fields[1] === "802-11-wireless")
                        saved.push(fields[0]);
                }
                root.savedWifiSsids = saved;
            }
        }
    }

    Process {
        id: wifiListProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const bySsid = new Map();
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const fields = root.splitEscaped(line);
                    const network = {
                        active: fields[0] === "*",
                        ssid: fields[1] ?? "",
                        strength: Number(fields[2] ?? 0),
                        security: fields[3] ?? "",
                        secure: Boolean(fields[3])
                    };
                    if (!network.ssid)
                        continue;
                    const previous = bySsid.get(network.ssid);
                    if (!previous || network.active
                            || network.strength > previous.strength)
                        bySsid.set(network.ssid, network);
                }
                root.wifiNetworks = Array.from(bySsid.values()).sort((a, b) => {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1;
                    return b.strength - a.strength;
                });
                const active = root.wifiNetworks.find(item => item.active);
                root.activeWifiSsid = active?.ssid ?? "";
                root.wifiStrength = active?.strength ?? 0;
                root.wifiScanning = false;
            }
        }
        onExited: root.wifiScanning = false
    }

    Process {
        id: wifiToggleProcess
        onExited: {
            wifiRadioProcess.running = true;
            Qt.callLater(() => root.refreshWifi(true));
        }
    }

    Process {
        id: wifiConnectProcess
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.statusMessage = text.trim();
            }
        }
        onExited: exitCode => {
            root.wifiConnecting = false;
            if (exitCode !== 0 && !root.passwordRequestedSsid)
                root.passwordRequestedSsid = root.wifiConnectTargetSsid;
            else if (exitCode === 0)
                root.statusMessage = "";
            Qt.callLater(() => root.refreshWifi(true));
        }
    }

    Process {
        id: wifiPasswordUpdateProcess

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.statusMessage = text.trim();
            }
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                wifiConnectProcess.exec([
                    "nmcli", "connection", "up", "id",
                    root.wifiConnectTargetSsid
                ]);
            } else {
                root.wifiConnecting = false;
                root.passwordRequestedSsid = root.wifiConnectTargetSsid;
            }
        }
    }
}
