pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    readonly property list<string> extensions: [
        "jpg", "jpeg", "png", "webp"
    ]
    readonly property string defaultDirectory:
        stripFileProtocol(StandardPaths.standardLocations(
            StandardPaths.PicturesLocation)[0]) + "/Wallpapers"
    readonly property string directory:
        ShellSettings.wallpaperDirectory
            ? ShellSettings.wallpaperDirectory : defaultDirectory
    readonly property string currentPath: Theme.wallpaperPath
    readonly property string cacheDirectory:
        Theme.stateDirectory + "/wallpaper-thumbnails"
    readonly property string previewScriptPath: stripFileProtocol(
        Qt.resolvedUrl("../scripts/wallpaper_preview.py"))
    readonly property list<string> transitionTypes: [
        "fade", "wipe", "disc", "stripes", "iris", "pixelate", "portal"
    ]

    property var wallpapers: []
    property var previewPaths: ({})
    property bool directoryReady: false
    property bool scanning: false
    property string transitionPath: ""
    property string activeTransition: "fade"
    property string lastRandomTransition: ""
    property int transitionSeed: 1

    signal changed(string path)

    readonly property int imageFillMode: {
        switch (ShellSettings.wallpaperFillMode) {
        case "Stretch":
            return Image.Stretch;
        case "PreserveAspectFit":
            return Image.PreserveAspectFit;
        case "Tile":
            return Image.Tile;
        case "TileVertically":
            return Image.TileVertically;
        case "TileHorizontally":
            return Image.TileHorizontally;
        case "Pad":
            return Image.Pad;
        default:
            return Image.PreserveAspectCrop;
        }
    }

    function stripFileProtocol(path) {
        return String(path).replace(/^file:\/\//, "");
    }

    function fileUrl(path) {
        const value = stripFileProtocol(path);
        return value ? "file://" + value : "";
    }

    function load() {
        // Forces singleton construction from shell.qml.
    }

    function refresh() {
        if (!directoryReady)
            return;
        if (scanProcess.running)
            scanProcess.running = false;
        scanProcess.items = [];
        scanProcess.previews = ({});
        scanProcess.running = true;
    }

    function previewUrl(path) {
        const cleanPath = stripFileProtocol(path);
        const preview = previewPaths[cleanPath] || cleanPath;
        return fileUrl(preview);
    }

    function setDirectory(path) {
        const cleanPath = stripFileProtocol(path).replace(/\/+$/, "");
        if (!cleanPath)
            return;
        ShellSettings.wallpaperDirectory = cleanPath;
        directoryReady = false;
        directoryProcess.running = true;
    }

    function apply(path) {
        const cleanPath = stripFileProtocol(path);
        if (!cleanPath)
            return;
        prepareTransition(cleanPath);
        Theme.setWallpaper(cleanPath, ShellSettings.wallpaperAutoTheme);
        changed(cleanPath);
    }

    function prepareTransition(path) {
        const cleanPath = stripFileProtocol(path);
        if (transitionPath === cleanPath)
            return activeTransition;

        let transition = ShellSettings.wallpaperTransition;
        if (transition === "random") {
            let candidates = transitionTypes.filter(
                item => item !== lastRandomTransition);
            if (candidates.length === 0)
                candidates = transitionTypes;
            transition = candidates[Math.floor(Math.random()
                * candidates.length)];
            lastRandomTransition = transition;
        }

        transitionPath = cleanPath;
        activeTransition = transition;
        transitionSeed = Math.floor(Math.random() * 1000000) + 1;
        return transition;
    }

    function transitionFor(path) {
        return prepareTransition(path);
    }

    function seededValue(outputName, salt) {
        let hash = transitionSeed + Math.round(Number(salt) * 7919);
        const name = String(outputName);
        for (let index = 0; index < name.length; ++index)
            hash = ((hash * 31) + name.charCodeAt(index)) % 2147483647;
        const value = Math.sin(hash * 12.9898) * 43758.5453;
        return value - Math.floor(value);
    }

    function currentIndex() {
        return wallpapers.indexOf(currentPath);
    }

    function next() {
        if (wallpapers.length === 0)
            return;
        const index = currentIndex();
        apply(wallpapers[index < 0
            ? 0 : (index + 1) % wallpapers.length]);
    }

    function previous() {
        if (wallpapers.length === 0)
            return;
        const index = currentIndex();
        apply(wallpapers[index < 0
            ? wallpapers.length - 1
            : (index - 1 + wallpapers.length) % wallpapers.length]);
    }

    function random() {
        if (wallpapers.length === 0)
            return;
        let index = Math.floor(Math.random() * wallpapers.length);
        if (wallpapers.length > 1
                && wallpapers[index] === currentPath)
            index = (index + 1) % wallpapers.length;
        apply(wallpapers[index]);
    }

    Component.onCompleted: directoryProcess.running = true

    Connections {
        target: ShellSettings

        function onWallpaperAutoThemeChanged() {
            if (ShellSettings.wallpaperAutoTheme && root.currentPath)
                Theme.fromWallpaper(root.currentPath);
        }

        function onWallpaperDirectoryChanged() {
            root.directoryReady = false;
            directoryProcess.running = true;
        }
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", root.directory, root.cacheDirectory]
        onExited: {
            root.directoryReady = true;
            root.refresh();
        }
    }

    Process {
        id: scanProcess

        property var items: []
        property var previews: ({})
        command: [
            "python3", root.previewScriptPath, "scan",
            root.directory, root.cacheDirectory
        ]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const item = JSON.parse(line);
                    scanProcess.items.push(item.path);
                    scanProcess.previews[item.path] = item.preview;
                } catch (error) {
                    console.warn("WallpaperService: invalid preview:", error);
                }
            }
        }
        onStarted: root.scanning = true
        onExited: {
            root.wallpapers = scanProcess.items;
            root.previewPaths = Object.assign({}, scanProcess.previews);
            root.scanning = false;
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            root.apply(path);
        }

        function next(): void {
            root.next();
        }

        function previous(): void {
            root.previous();
        }

        function random(): void {
            root.random();
        }

        function setDirectory(path: string): void {
            root.setDirectory(path);
        }

        function status(): string {
            return JSON.stringify({
                path: root.currentPath,
                directory: root.directory,
                count: root.wallpapers.length,
                autoTheme: ShellSettings.wallpaperAutoTheme,
                transition: ShellSettings.wallpaperTransition,
                activeTransition: root.activeTransition,
                scheme: Theme.scheme
            });
        }
    }
}
