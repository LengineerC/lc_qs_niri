pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property string loginName: ""
    property string realName: ""
    property string systemAvatarPath: ""
    property real uptimeSeconds: 0

    readonly property string homePath: stripFileProtocol(
        StandardPaths.standardLocations(StandardPaths.HomeLocation)[0])
    readonly property string displayName:
        realName || loginName || I18n.tr("user")
    readonly property string avatarPath:
        ShellSettings.userAvatarPath || systemAvatarPath
    readonly property string avatarUrl: fileUrl(avatarPath)

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function stripFileProtocol(path) {
        return String(path || "").replace(/^file:\/\//, "");
    }

    function fileUrl(path) {
        const value = stripFileProtocol(path);
        return value ? "file://" + value : "";
    }

    function parseAccount(text) {
        const fields = String(text).trim().split(":");
        if (fields.length < 6)
            return;
        const gecos = fields[4].split(",")[0].trim();
        if (gecos)
            realName = gecos;
    }

    function parseUptime(text) {
        const value = Number(String(text).trim().split(/\s+/)[0]);
        if (Number.isFinite(value) && value >= 0)
            uptimeSeconds = value;
    }

    function formatUptime() {
        const totalMinutes = Math.max(0,
            Math.floor(uptimeSeconds / 60));
        const days = Math.floor(totalMinutes / 1440);
        const hours = Math.floor((totalMinutes % 1440) / 60);
        const minutes = totalMinutes % 60;
        if (I18n.language === "en_US") {
            if (days > 0)
                return days + "d " + hours + "h " + minutes + "m";
            if (hours > 0)
                return hours + "h " + minutes + "m";
            return minutes + "m";
        }
        if (days > 0)
            return days + "天 " + hours + "小时 " + minutes + "分钟";
        if (hours > 0)
            return hours + "小时 " + minutes + "分钟";
        return minutes + "分钟";
    }

    function probeAvatar() {
        if (!loginName || avatarProbe.running)
            return;
        avatarProbe.command = [
            "sh", "-c",
            "for p in \"$1\" \"$2\" \"$3\"; do "
                + "[ -f \"$p\" ] && { printf '%s' \"$p\"; exit 0; }; "
                + "done",
            "avatar-probe",
            "/var/lib/AccountsService/icons/" + loginName,
            homePath + "/.face",
            homePath + "/.face.icon"
        ];
        avatarProbe.running = true;
    }

    function powerOff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function logout() {
        Quickshell.execDetached([
            "niri", "msg", "action", "quit", "--skip-confirmation"
        ]);
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    Component.onCompleted: {
        loginProcess.running = true;
        uptimeFile.reload();
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.parseUptime(text())
    }

    Process {
        id: loginProcess
        command: ["id", "-un"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loginName = text.trim();
                if (!root.loginName)
                    return;
                accountProcess.command = [
                    "getent", "passwd", root.loginName
                ];
                accountProcess.running = true;
                root.probeAvatar();
            }
        }
    }

    Process {
        id: accountProcess
        stdout: StdioCollector {
            onStreamFinished: root.parseAccount(text)
        }
    }

    Process {
        id: avatarProbe
        stdout: StdioCollector {
            onStreamFinished:
                root.systemAvatarPath = text.trim()
        }
    }
}
