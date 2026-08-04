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
    property string wifiDetailsSsid: ""
    property var wifiDetails: ({})
    property bool wifiDetailsLoading: false
    property string wifiDetailsQuerySsid: ""
    property string wifiDetailsPendingSsid: ""
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

    function wifiBand(frequency) {
        const mhz = Number.parseFloat(String(frequency ?? ""));
        if (!Number.isFinite(mhz) || mhz <= 0)
            return "—";
        if (mhz >= 5925)
            return "6 GHz";
        if (mhz >= 4900)
            return "5 GHz";
        if (mhz >= 2400)
            return "2.4 GHz";
        return String(frequency);
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
            "nmcli", "-t", "-f",
            "IN-USE,SSID,SIGNAL,SECURITY,BSSID,CHAN,FREQ,RATE,DEVICE",
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
            statusMessage = "";
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

    function cancelWifiPassword() {
        passwordRequestedSsid = "";
        statusMessage = "";
    }

    function hideWifiDetails() {
        wifiDetailsSsid = "";
        wifiDetails = ({});
        wifiDetailsLoading = false;
        wifiDetailsPendingSsid = "";
    }

    function toggleWifiDetails(ssid) {
        if (wifiDetailsSsid === ssid) {
            hideWifiDetails();
            return;
        }
        showWifiDetails(ssid);
    }

    function showWifiDetails(ssid) {
        const network = wifiNetworks.find(item => item.ssid === ssid);
        if (!network)
            return;

        wifiDetailsSsid = ssid;
        wifiDetails = Object.assign({}, network);
        wifiDetailsLoading = false;
        if (network.active && network.device)
            queryWifiDeviceDetails(ssid, network.device);
    }

    function queryWifiDeviceDetails(ssid, device) {
        if (wifiDetailsProcess.running) {
            wifiDetailsPendingSsid = ssid;
            return;
        }

        wifiDetailsQuerySsid = ssid;
        wifiDetailsLoading = true;
        wifiDetailsProcess.exec([
            "nmcli", "-t", "-f",
            "GENERAL.CONNECTION,GENERAL.DEVICE,GENERAL.HWADDR,GENERAL.MTU,"
                + "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,"
                + "IP6.ADDRESS,IP6.GATEWAY,IP6.DNS",
            "device", "show", device
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
                        secure: Boolean(fields[3]) && fields[3] !== "--",
                        bssid: fields[4] ?? "",
                        channel: fields[5] ?? "",
                        frequency: fields[6] ?? "",
                        rate: fields[7] ?? "",
                        device: fields[8] ?? ""
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
                if (root.wifiDetailsSsid) {
                    const selected = root.wifiNetworks.find(item =>
                        item.ssid === root.wifiDetailsSsid);
                    if (selected)
                        root.wifiDetails = Object.assign(
                            {}, root.wifiDetails, selected);
                    else
                        root.hideWifiDetails();
                }
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
            const target = root.wifiNetworks.find(item =>
                item.ssid === root.wifiConnectTargetSsid);
            if (exitCode !== 0 && target?.secure
                    && !root.passwordRequestedSsid)
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

    Process {
        id: wifiDetailsProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.wifiDetailsSsid !== root.wifiDetailsQuerySsid)
                    return;

                const details = {};
                const ipv4Addresses = [];
                const ipv6Addresses = [];
                const ipv4Dns = [];
                const ipv6Dns = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const fields = root.splitEscaped(line);
                    const key = fields[0] ?? "";
                    const value = fields.slice(1).join(":");
                    if (key === "GENERAL.CONNECTION")
                        details.connection = value;
                    else if (key === "GENERAL.DEVICE")
                        details.device = value;
                    else if (key === "GENERAL.HWADDR")
                        details.macAddress = value;
                    else if (key === "GENERAL.MTU")
                        details.mtu = value;
                    else if (key.startsWith("IP4.ADDRESS"))
                        ipv4Addresses.push(value);
                    else if (key === "IP4.GATEWAY")
                        details.ipv4Gateway = value;
                    else if (key.startsWith("IP4.DNS"))
                        ipv4Dns.push(value);
                    else if (key.startsWith("IP6.ADDRESS"))
                        ipv6Addresses.push(value);
                    else if (key === "IP6.GATEWAY")
                        details.ipv6Gateway = value;
                    else if (key.startsWith("IP6.DNS"))
                        ipv6Dns.push(value);
                }
                details.ipv4Address = ipv4Addresses.join(", ");
                details.ipv6Address = ipv6Addresses.join(", ");
                details.ipv4Dns = ipv4Dns.join(", ");
                details.ipv6Dns = ipv6Dns.join(", ");
                root.wifiDetails = Object.assign(
                    {}, root.wifiDetails, details);
            }
        }

        onExited: {
            if (root.wifiDetailsSsid === root.wifiDetailsQuerySsid)
                root.wifiDetailsLoading = false;

            if (root.wifiDetailsPendingSsid) {
                const pendingSsid = root.wifiDetailsPendingSsid;
                root.wifiDetailsPendingSsid = "";
                const network = root.wifiNetworks.find(item =>
                    item.ssid === pendingSsid);
                if (network?.active && network.device
                        && root.wifiDetailsSsid === pendingSsid)
                    Qt.callLater(() => root.queryWifiDeviceDetails(
                        pendingSsid, network.device));
            }
        }
    }
}
