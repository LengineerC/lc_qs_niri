pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property string userName: ""
    property string hostName: ""
    property string osName: ""
    property string osId: ""
    property string osIdLike: ""
    property string windowManager: ""
    property string kernel: ""
    property string shellName: ""
    property bool loading: false
    property bool ready: false
    property string errorMessage: ""

    readonly property string title: {
        const user = userName || UserService.loginName;
        if (user && hostName)
            return user + "@" + hostName;
        return user || hostName || "fastfetch";
    }
    readonly property string systemIcon: distroIcon(osId, osIdLike)

    function distroIcon(id, idLike) {
        const icons = {
            "alpine": "",
            "arch": "",
            "centos": "",
            "debian": "",
            "elementary": "",
            "fedora": "",
            "freebsd": "",
            "gentoo": "",
            "linuxmint": "",
            "mint": "",
            "mageia": "",
            "manjaro": "",
            "nixos": "",
            "opensuse": "",
            "opensuse-leap": "",
            "opensuse-tumbleweed": "",
            "suse": "",
            "raspbian": "",
            "rhel": "",
            "redhat": "",
            "slackware": "",
            "ubuntu": "",
            "kali": "",
            "pop": "",
            "pop_os": "",
            "rocky": "",
            "solus": "",
            "void": "",
            "android": "",
            "darwin": "",
            "macos": "",
            "windows": ""
        };
        const systemId = String(id ?? "").trim().toLowerCase();
        if (icons[systemId])
            return icons[systemId];

        const families = String(idLike ?? "").toLowerCase()
            .split(/[\s,]+/);
        for (let index = 0; index < families.length; index++) {
            if (icons[families[index]])
                return icons[families[index]];
        }

        if (systemId.indexOf("bsd") >= 0)
            return "";
        return "";
    }

    function load() {
        if (fastfetchProcess.running)
            return;

        loading = true;
        errorMessage = "";
        fastfetchProcess.running = true;
    }

    function moduleResult(modules, type) {
        for (let index = 0; index < modules.length; index++) {
            const item = modules[index];
            if (item && item.type === type)
                return item.result ?? {};
        }
        return {};
    }

    function executableName(path) {
        const parts = String(path ?? "").split("/");
        return parts.length > 0 ? parts[parts.length - 1] : "";
    }

    function parseOutput(text) {
        try {
            const modules = JSON.parse(String(text ?? ""));
            if (!Array.isArray(modules))
                throw new Error("Unexpected Fastfetch response");

            const titleData = moduleResult(modules, "Title");
            const osData = moduleResult(modules, "OS");
            const wmData = moduleResult(modules, "WM");
            const kernelData = moduleResult(modules, "Kernel");

            userName = String(titleData.userName
                ?? UserService.loginName ?? "");
            hostName = String(titleData.hostName ?? "");
            osName = String(osData.prettyName ?? osData.name ?? "");
            osId = String(osData.id ?? "").toLowerCase();
            osIdLike = String(osData.idLike ?? "").toLowerCase();
            windowManager = String(wmData.prettyName
                ?? wmData.processName ?? "");
            kernel = String(kernelData.release ?? "");
            shellName = executableName(titleData.userShell);
            ready = true;
            errorMessage = "";
        } catch (error) {
            ready = false;
            errorMessage = String(error);
            console.warn("FastfetchService: cannot parse output:", error);
        }
    }

    Component.onCompleted: load()

    Process {
        id: fastfetchProcess

        command: [
            "fastfetch",
            "-s", "title:os:wm:kernel",
            "--format", "json"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.parseOutput(text)
        }

        stderr: StdioCollector {
            id: fastfetchError
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode === 0)
                return;

            root.ready = false;
            root.errorMessage = fastfetchError.text.trim()
                || "Fastfetch exited with code " + exitCode;
            console.warn("FastfetchService:", root.errorMessage);
        }
    }
}
