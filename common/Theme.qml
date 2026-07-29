pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string mode: "dark"
    property string scheme: "scheme-tonal-spot"
    property string wallpaperPath: ""
    property string sourceColor: "#6750a4"
    property bool ready: false
    property bool generating: false
    property bool storageReady: false
    property string generatedOutput: ""
    property bool themeStateLoaded: false
    property bool wallpaperStateLoaded: false
    property bool startupThemeChecked: false
    property var pendingSourceArguments: null

    readonly property bool darkMode: mode === "dark"
    readonly property string stateDirectory: stripFileProtocol(
        StandardPaths.standardLocations(StandardPaths.StateLocation)[0])
        + "/test"
    readonly property string themeFilePath: stateDirectory + "/theme.json"
    readonly property string wallpaperFilePath: stateDirectory + "/wallpaper.path"
    readonly property string matugenConfigPath: stripFileProtocol(
        Quickshell.shellPath("theme/matugen.toml"))

    readonly property list<string> colorKeys: [
        "background",
        "on_background",
        "surface",
        "surface_dim",
        "surface_bright",
        "surface_container_lowest",
        "surface_container_low",
        "surface_container",
        "surface_container_high",
        "surface_container_highest",
        "on_surface",
        "surface_variant",
        "on_surface_variant",
        "inverse_surface",
        "inverse_on_surface",
        "outline",
        "outline_variant",
        "shadow",
        "scrim",
        "surface_tint",
        "primary",
        "on_primary",
        "primary_container",
        "on_primary_container",
        "inverse_primary",
        "secondary",
        "on_secondary",
        "secondary_container",
        "on_secondary_container",
        "tertiary",
        "on_tertiary",
        "tertiary_container",
        "on_tertiary_container",
        "error",
        "on_error",
        "error_container",
        "on_error_container",
        "primary_fixed",
        "primary_fixed_dim",
        "on_primary_fixed",
        "on_primary_fixed_variant",
        "secondary_fixed",
        "secondary_fixed_dim",
        "on_secondary_fixed",
        "on_secondary_fixed_variant",
        "tertiary_fixed",
        "tertiary_fixed_dim",
        "on_tertiary_fixed",
        "on_tertiary_fixed_variant",
        "source_color"
    ]

    readonly property QtObject palette: QtObject {
        property color m3background: "#141313"
        property color m3onBackground: "#e6e1e1"
        property color m3surface: "#141313"
        property color m3surfaceDim: "#141313"
        property color m3surfaceBright: "#3a3939"
        property color m3surfaceContainerLowest: "#0f0e0e"
        property color m3surfaceContainerLow: "#1c1b1c"
        property color m3surfaceContainer: "#201f20"
        property color m3surfaceContainerHigh: "#2b2a2a"
        property color m3surfaceContainerHighest: "#363435"
        property color m3onSurface: "#e6e1e1"
        property color m3surfaceVariant: "#49464a"
        property color m3onSurfaceVariant: "#cbc5ca"
        property color m3inverseSurface: "#e6e1e1"
        property color m3inverseOnSurface: "#313030"
        property color m3outline: "#948f94"
        property color m3outlineVariant: "#49464a"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#cbc4cb"
        property color m3primary: "#cbc4cb"
        property color m3onPrimary: "#322f34"
        property color m3primaryContainer: "#2d2a2f"
        property color m3onPrimaryContainer: "#bcb6bc"
        property color m3inversePrimary: "#615d63"
        property color m3secondary: "#cac5c8"
        property color m3onSecondary: "#323032"
        property color m3secondaryContainer: "#4d4b4d"
        property color m3onSecondaryContainer: "#ece6e9"
        property color m3tertiary: "#d1c3c6"
        property color m3onTertiary: "#372e30"
        property color m3tertiaryContainer: "#31292b"
        property color m3onTertiaryContainer: "#c1b4b7"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3primaryFixed: "#e7e0e7"
        property color m3primaryFixedDim: "#cbc4cb"
        property color m3onPrimaryFixed: "#1d1b1f"
        property color m3onPrimaryFixedVariant: "#49454b"
        property color m3secondaryFixed: "#e6e1e4"
        property color m3secondaryFixedDim: "#cac5c8"
        property color m3onSecondaryFixed: "#1d1b1d"
        property color m3onSecondaryFixedVariant: "#484648"
        property color m3tertiaryFixed: "#eddfe1"
        property color m3tertiaryFixedDim: "#d1c3c6"
        property color m3onTertiaryFixed: "#211a1c"
        property color m3onTertiaryFixedVariant: "#4e4447"
        property color m3sourceColor: "#6750a4"
        property color m3success: "#b5ccba"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374b3e"
        property color m3onSuccessContainer: "#d1e9d6"
    }

    function stripFileProtocol(path) {
        return String(path).replace(/^file:\/\//, "");
    }

    function qmlPropertyFor(key) {
        return "m3" + key.replace(/_([a-z])/g, function(_, letter) {
            return letter.toUpperCase();
        });
    }

    function applyColorMap(colors) {
        for (const key of colorKeys) {
            if (!colors[key])
                continue;

            const propertyName = qmlPropertyFor(key);
            if (palette.hasOwnProperty(propertyName))
                palette[propertyName] = colors[key];
        }

        if (colors.source_color)
            sourceColor = colors.source_color;
    }

    function colorMap() {
        const colors = {};
        for (const key of colorKeys) {
            const propertyName = qmlPropertyFor(key);
            if (palette.hasOwnProperty(propertyName))
                colors[key] = palette[propertyName].toString();
        }
        return colors;
    }

    function relativeLuminance(colorValue) {
        function linearChannel(value) {
            return value <= 0.04045
                ? value / 12.92
                : Math.pow((value + 0.055) / 1.055, 2.4);
        }

        return linearChannel(colorValue.r) * 0.2126
            + linearChannel(colorValue.g) * 0.7152
            + linearChannel(colorValue.b) * 0.0722;
    }

    function paletteMatchesMode() {
        const isLightPalette = relativeLuminance(
            palette.m3background) >= 0.45;
        return darkMode ? !isLightPalette : isLightPalette;
    }

    function ensureStartupTheme() {
        if (startupThemeChecked || !themeStateLoaded
                || !wallpaperStateLoaded)
            return;

        startupThemeChecked = true;
        if (paletteMatchesMode())
            return;

        console.warn("Theme: saved palette does not match mode; regenerating");
        if (wallpaperPath)
            runMatugen(["image", wallpaperPath]);
        else
            runMatugen(["color", "hex", sourceColor]);
    }

    function applySavedTheme(data) {
        try {
            const state = JSON.parse(data);
            if (state.mode === "dark" || state.mode === "light")
                mode = state.mode;
            if (state.scheme)
                scheme = state.scheme;
            if (state.wallpaperPath)
                wallpaperPath = state.wallpaperPath;
            if (state.sourceColor)
                sourceColor = state.sourceColor;
            if (state.colors)
                applyColorMap(state.colors);
            ready = true;
        } catch (error) {
            console.warn("Theme: cannot parse saved theme:", error);
            ready = true;
        }
        themeStateLoaded = true;
        Qt.callLater(ensureStartupTheme);
    }

    function applyMatugen(data) {
        try {
            const output = JSON.parse(data);
            const colors = {};

            for (const key of colorKeys) {
                const value = output.colors?.[key]?.default?.color;
                if (value)
                    colors[key] = value;
            }

            applyColorMap(colors);
            save();
        } catch (error) {
            console.warn("Theme: cannot parse matugen output:", error);
        }
    }

    function save() {
        if (!storageReady)
            return;

        themeStorage.setText(JSON.stringify({
            version: 1,
            mode: mode,
            scheme: scheme,
            wallpaperPath: wallpaperPath,
            sourceColor: sourceColor,
            colors: colorMap()
        }, null, 2));
    }

    function startPendingMatugen() {
        if (pendingSourceArguments === null || matugenProcess.running)
            return;

        const sourceArguments = pendingSourceArguments;
        pendingSourceArguments = null;
        generatedOutput = "";
        generating = true;
        matugenProcess.requestedMode = mode;

        matugenProcess.exec([
            "matugen",
            "--config", matugenConfigPath,
            "--json", "hex",
            "--quiet",
            "--mode", matugenProcess.requestedMode,
            "--type", scheme,
            "--source-color-index", "0"
        ].concat(sourceArguments));
    }

    function runMatugen(sourceArguments) {
        pendingSourceArguments = sourceArguments.slice();
        generating = true;
        if (matugenProcess.running)
            matugenProcess.running = false;
        else
            startPendingMatugen();
    }

    function fromWallpaper(path) {
        const cleanPath = stripFileProtocol(path);
        if (!cleanPath)
            return;

        wallpaperPath = cleanPath;
        if (storageReady)
            wallpaperStorage.setText(cleanPath + "\n");
        runMatugen(["image", cleanPath]);
    }

    function fromColor(colorValue) {
        sourceColor = colorValue;
        runMatugen(["color", "hex", colorValue]);
    }

    function setMode(newMode) {
        if (newMode !== "dark" && newMode !== "light")
            return;
        if (mode === newMode && ready)
            return;

        mode = newMode;
        save();
        if (wallpaperPath)
            runMatugen(["image", wallpaperPath]);
        else
            fromColor(sourceColor);
    }

    function toggleMode() {
        setMode(darkMode ? "light" : "dark");
    }

    function setScheme(newScheme) {
        const allowed = [
            "scheme-content",
            "scheme-expressive",
            "scheme-fidelity",
            "scheme-fruit-salad",
            "scheme-monochrome",
            "scheme-neutral",
            "scheme-rainbow",
            "scheme-tonal-spot",
            "scheme-vibrant"
        ];
        if (!allowed.includes(newScheme))
            return;

        scheme = newScheme;
        if (wallpaperPath)
            runMatugen(["image", wallpaperPath]);
        else
            fromColor(sourceColor);
    }

    function load() {
        // Forces singleton construction from shell.qml.
    }

    Component.onCompleted: directoryProcess.running = true

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", root.stateDirectory]
        onExited: {
            root.storageReady = true;
        }
    }

    Process {
        id: matugenProcess

        property int exitCode: 0
        property string requestedMode: ""

        stdout: StdioCollector {
            onStreamFinished: {
                root.generatedOutput = text;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn("Theme: matugen:", text.trim());
            }
        }

        onExited: (exitCode, exitStatus) => {
            matugenProcess.exitCode = exitCode;
            if (exitCode === 0 && root.generatedOutput
                    && matugenProcess.requestedMode === root.mode)
                root.applyMatugen(root.generatedOutput);
            else if (exitCode !== 0
                    && root.pendingSourceArguments === null)
                console.warn("Theme: matugen exited with", exitCode);

            if (root.pendingSourceArguments !== null)
                Qt.callLater(root.startPendingMatugen);
            else
                root.generating = false;
        }
    }

    FileView {
        id: themeStorage

        path: root.storageReady ? root.themeFilePath : "/dev/null"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            if (root.storageReady)
                root.applySavedTheme(text());
        }
        onLoadFailed: error => {
            if (!root.storageReady)
                return;
            root.ready = true;
            root.themeStateLoaded = true;
            if (error === FileViewError.FileNotFound) {
                Qt.callLater(() => root.save());
                Qt.callLater(root.ensureStartupTheme);
            }
        }
    }

    FileView {
        id: wallpaperStorage

        path: root.storageReady ? root.wallpaperFilePath : "/dev/null"
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            if (!root.storageReady)
                return;
            const path = text().trim();
            const pathChanged = path && path !== root.wallpaperPath;
            if (pathChanged)
                root.wallpaperPath = path;
            root.wallpaperStateLoaded = true;

            if (root.startupThemeChecked && pathChanged)
                root.runMatugen(["image", path]);
            else
                Qt.callLater(root.ensureStartupTheme);
        }
        onLoadFailed: error => {
            if (root.storageReady && error === FileViewError.FileNotFound) {
                root.wallpaperStateLoaded = true;
                Qt.callLater(() => wallpaperStorage.setText(""));
                Qt.callLater(root.ensureStartupTheme);
            }
        }
    }

    IpcHandler {
        target: "theme"

        function toggle(): void {
            root.toggleMode();
        }

        function setMode(mode: string): void {
            root.setMode(mode);
        }

        function setScheme(scheme: string): void {
            root.setScheme(scheme);
        }

        function setAccent(color: string): void {
            root.fromColor(color);
        }

        function fromWallpaper(path: string): void {
            root.fromWallpaper(path);
        }

        function status(): string {
            return JSON.stringify({
                mode: root.mode,
                scheme: root.scheme,
                wallpaperPath: root.wallpaperPath,
                sourceColor: root.sourceColor,
                generating: root.generating
            });
        }
    }
}
