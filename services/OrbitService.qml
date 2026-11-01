pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import "../modules/orbit/OrbitMath.js" as OrbitMath

Singleton {
    id: root
    property bool shown: false
    property string outputName: ""
    property real originX: -1
    property real originY: -1
    property var items: defaultItems()
    property string error: ""
    property bool storageReady: false
    property bool saving: false
    property bool configReady: false
    property var document: ({})
    property var pendingDocument: null
    signal configSaved()
    signal configSaveFailed(string message)
    function saveGroup(index, children, original) {
        try {
            if (!storageReady || !configReady || saving) throw new Error("配置尚未就绪，请稍后重试");
            const baseline = JSON.parse(original);
            if (JSON.stringify(items[index]) !== JSON.stringify(baseline[index]))
                throw new Error("此分组已被其他操作修改，请重置后重新编辑");
            const next = JSON.parse(JSON.stringify(document));
            next.schemaVersion = 2;
            next.items = JSON.parse(JSON.stringify(items));
            if (!next.items[index]?.children) throw new Error("菜单已不存在");
            next.items[index].children = children;
            OrbitMath.validate(next.items);
            pendingDocument = next;
            saving = true;
            config.setText(JSON.stringify(next, null, 2));
            return true;
        } catch (e) { error = String(e); return false; }
    }
    property int revision: 0
    property string pending: ""
    readonly property string configPath: ShellSettings.stateDirectory + "/orbit-menu.json"
    function defaultItems() {
        return [
            {name: "Terminal", desc: "终端", icon: "󰞷", action: "terminal"},
            {id: "tools", name: "System Tools", desc: "系统工具", icon: "󰘳", children: [
                {name: "Settings", desc: "外观与系统设置", icon: "󰒓", action: "settings"},
                {name: "Desktop", desc: "桌面内容目录", icon: "󰉋", action: "desktop"}
            ]},
            {id: "websites", name: "Websites", desc: "常用网站", icon: "󰖟", children: [
                {name: "GitHub", desc: "代码仓库", icon: "󰊤", url: "https://github.com"},
                {name: "Bilibili", desc: "哔哩哔哩", icon: "󰕧", url: "https://www.bilibili.com"},
                {name: "Zhihu", desc: "知乎", icon: "󰖟", url: "https://www.zhihu.com"}
            ]},
            {id: "wallpapers", name: "Wallpapers", desc: "壁纸", icon: "󰸉", children: [
                {name: "Next", desc: "下一张壁纸", icon: "󰒭", action: "wallpaperNext"},
                {name: "Random", desc: "随机壁纸", icon: "󰒟", action: "wallpaperRandom"}
            ]}
        ];
    }
    function openOnOutput(name, x, y) {
        ++revision;
        pending = "";
        originX = x === undefined ? -1 : x;
        originY = y === undefined ? -1 : y;
        outputName = name;
        shown = true;
    }
    function close() { ++revision; pending = ""; shown = false; }
    function toggle() {
        if (shown || pending) { close(); return; }
        pending = "open";
        ++revision;
        if (!focused.running) focused.running = true;
    }
    function execute(item) {
        close();
        if (item.shell) { Quickshell.execDetached(["sh", "-c", item.shell]); return; }
        if (item.command) { Quickshell.execDetached(item.command); return; }
        if (item.url) { Qt.openUrlExternally(item.url); return; }
        switch (item.action) {
        case "terminal": Quickshell.execDetached([Quickshell.env("TERMINAL") || "kitty"]); break;
        case "settings": SettingsLauncher.open(); break;
        case "desktop": DesktopService.open(DesktopService.directoryUrl); break;
        case "wallpaperNext": WallpaperService.next(); break;
        case "wallpaperRandom": WallpaperService.random(); break;
        case "lock": LockService.lock(); break;
        }
    }
    Process {
        id: focused
        property int requestRevision: 0
        property string buffer: ""
        command: ["niri", "msg", "--json", "focused-output"]
        onStarted: { requestRevision = root.revision; buffer = ""; }
        stdout: StdioCollector { onStreamFinished: focused.buffer = text }
        onExited: {
            if (!root.pending) return;
            if (requestRevision !== root.revision) { running = true; return; }
            let name = "";
            try { name = JSON.parse(buffer).name || ""; } catch (e) {}
            if (!name) name = Quickshell.screens[0]?.name || "";
            if (name) root.openOnOutput(name); else root.pending = "";
        }
    }
    Process {
        command: ["mkdir", "-p", ShellSettings.stateDirectory]
        running: true
        onExited: (code, status) => { root.storageReady = code === 0; }
    }
    FileView {
        id: config
        path: root.storageReady ? root.configPath : ""
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const previous = JSON.parse(text());
                const next = OrbitMath.migrate(previous);
                root.items = OrbitMath.validate(next.items);
                root.document = next;
                root.configReady = true;
                root.error = "";
                if (JSON.stringify(previous) !== JSON.stringify(next))
                    setText(JSON.stringify(next, null, 2));
            } catch (e) { root.error = "Orbit: " + e; console.warn(root.error); }
        }
        onSaved: {
            if (!root.saving) return;
            root.document = root.pendingDocument;
            root.items = root.pendingDocument.items;
            root.pendingDocument = null;
            root.saving = false;
            root.error = "";
            root.configSaved();
        }
        onSaveFailed: failure => {
            root.error = "无法保存星环配置: " + failure;
            root.saving = false;
            root.pendingDocument = null;
            root.configSaveFailed(root.error);
        }
        onLoadFailed: failure => {
            if (root.storageReady && failure === FileViewError.FileNotFound)
                setText(JSON.stringify({schemaVersion: 2, items: root.defaultItems()}, null, 2));
        }
    }
    IpcHandler {
        target: "orbit"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
    }
}
