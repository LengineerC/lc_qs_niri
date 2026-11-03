pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import "DesktopOpenGate.js" as OpenGate

Singleton {
    id: root
    readonly property string directory: ShellSettings.stateDirectory + "/desktop"
    readonly property string directoryUrl: "file://" + directory.split("/").map(encodeURIComponent).join("/")
    property var entries: []
    property var positions: ({})
    property string error: ""
    property bool ready: false
    property var pending: []
    property var openQueue: []
    property var openGate: OpenGate.createState()
    readonly property int openCooldownMs: 1200
    readonly property string scriptPath: decodeURIComponent(String(Qt.resolvedUrl(
        "../scripts/desktop_files.py")).replace(/^file:\/\//, ""))

    function send(message) {
        error = "";
        if (ready)
            backend.write(JSON.stringify(message) + "\n");
        else
            pending.push(message);
    }
    function add(sources) { send({action: "link", sources: sources}); }
    function addAt(sources, screen, x, y) {
        sources.forEach((source, index) => send({action: "link", sources: [source],
            screen: screen, x: x + index * 24, y: y + index * 24}));
    }
    function move(name, screen, x, y) {
        send({action: "move", name: name, screen: screen, x: x, y: y});
    }
    function moveMany(items, screen) { send({action: "moveMany", items: items, screen: screen}); }
    function removeLinks(names) { send({action: "unlinkMany", names: names}); }
    function renameLinks(items) { send({action: "renameMany", items: items}); }
    function removeLink(name) { send({action: "unlink", name: name}); }
    function open(url) {
        error = "";
        const key = String(url);
        if (!OpenGate.tryAcquire(openGate, key, Date.now(), openCooldownMs))
            return;
        openQueue.push({url: key, key: key});
        startOpen();
    }
    function startOpen() {
        if (opener.running || openQueue.length === 0)
            return;
        const request = openQueue.shift();
        opener.url = request.url;
        opener.key = request.key;
        opener.diagnostics = "";
        opener.running = true;
    }
    Process {
        id: opener
        property string url: ""
        property string key: ""
        property string diagnostics: ""
        command: ["python3", root.scriptPath, "--open", url]
        stderr: SplitParser { onRead: line => opener.diagnostics += line + "\n" }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.error = opener.diagnostics.trim() || I18n.tr("desktopOpenFailed");
            OpenGate.release(root.openGate, opener.key, Date.now());
            Qt.callLater(root.startOpen);
        }
    }

    Process {
        id: backend
        command: ["python3", root.scriptPath,
            root.directory, ShellSettings.stateDirectory + "/desktop-positions.json"]
        stdinEnabled: true
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    if (data.error !== undefined) {
                        root.error = data.error;
                        return;
                    }
                    root.positions = data.positions;
                    if (JSON.stringify(root.entries) !== JSON.stringify(data.entries))
                        root.entries = data.entries;
                    root.ready = true;
                    for (const message of root.pending)
                        backend.write(JSON.stringify(message) + "\n");
                    root.pending = [];
                } catch (error) { console.warn("DesktopService:", error); }
            }
        }
        onExited: {
            root.ready = false;
            restart.restart();
        }
    }
    Timer {
        id: restart
        interval: 2000
        onTriggered: backend.running = true
    }
}
