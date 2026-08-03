pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    component WallpaperWindow: PanelWindow {
        id: wallpaperWindow

        required property ShellScreen modelData
        property bool overviewBackdrop: false
        property string displayedSource: ""
        property string nextSource: ""
        property string transitionName: "fade"
        property real transitionProgress: 0
        property bool effectActive: false
        property real wipeDirection: 0
        property real stripeCount: 12
        property real stripeAngle: 0
        property vector2d effectCenter: Qt.vector2d(0.5, 0.5)
        readonly property real transitionKind: {
            switch (transitionName) {
            case "wipe": return 1;
            case "disc": return 2;
            case "stripes": return 3;
            case "iris": return 4;
            case "pixelate": return 5;
            case "portal": return 6;
            default: return 0;
            }
        }

        screen: modelData
        color: "black"
        exclusiveZone: -1

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: overviewBackdrop
            ? "quickshell:overview-wallpaper"
            : "quickshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {}

        function sourceUrl(path) {
            return path ? WallpaperService.fileUrl(path) : "";
        }

        function configureTransition(path) {
            transitionName = WallpaperService.transitionFor(path);
            const outputName = modelData.name;
            wipeDirection = Math.floor(
                WallpaperService.seededValue(outputName, 1) * 4);
            stripeCount = 7 + Math.floor(
                WallpaperService.seededValue(outputName, 2) * 14);
            stripeAngle = WallpaperService.seededValue(outputName, 3) * 360;
            effectCenter = Qt.vector2d(
                0.18 + WallpaperService.seededValue(outputName, 4) * 0.64,
                0.18 + WallpaperService.seededValue(outputName, 5) * 0.64);
        }

        function finishTransition() {
            if (!nextSource)
                return;
            displayedSource = nextSource;
            nextSource = "";
            transitionProgress = 0;
            effectActive = false;
        }

        function startTransition() {
            if (!nextSource || nextWallpaper.status !== Image.Ready)
                return;
            if (transitionName === "none") {
                finishTransition();
                return;
            }

            effectActive = true;
            currentTexture.scheduleUpdate();
            nextTexture.scheduleUpdate();
            transitionDelay.restart();
        }

        function changeWallpaper(path) {
            const source = sourceUrl(path);
            if (!source || source === displayedSource)
                return;
            if (!displayedSource) {
                displayedSource = source;
                return;
            }

            transition.stop();
            transitionDelay.stop();
            effectActive = false;
            transitionProgress = 0;
            configureTransition(path);
            nextSource = source;
            if (nextWallpaper.status === Image.Ready)
                Qt.callLater(startTransition);
        }

        Component.onCompleted:
            changeWallpaper(WallpaperService.currentPath)

        Connections {
            target: WallpaperService

            function onCurrentPathChanged() {
                wallpaperWindow.changeWallpaper(
                    WallpaperService.currentPath);
            }
        }

        Item {
            id: wallpaperContent
            anchors.fill: parent

            layer.enabled: wallpaperWindow.overviewBackdrop
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: Appearance.px(64)
                blurMultiplier: 1
            }

            Image {
                id: currentWallpaper
                anchors.fill: parent
                source: wallpaperWindow.displayedSource
                fillMode: WallpaperService.imageFillMode
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
            }

            Image {
                id: nextWallpaper
                anchors.fill: parent
                source: wallpaperWindow.nextSource
                fillMode: WallpaperService.imageFillMode
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                opacity: 0

                onStatusChanged: {
                    if (status === Image.Ready && source)
                        wallpaperWindow.startTransition();
                    else if (status === Image.Error) {
                        wallpaperWindow.nextSource = "";
                        wallpaperWindow.effectActive = false;
                        wallpaperWindow.transitionProgress = 0;
                    }
                }
            }

            ShaderEffectSource {
                id: currentTexture
                sourceItem: currentWallpaper
                hideSource: wallpaperWindow.effectActive
                live: false
                recursive: false
            }

            ShaderEffectSource {
                id: nextTexture
                sourceItem: nextWallpaper
                hideSource: true
                live: false
                recursive: false
            }

            ShaderEffect {
                anchors.fill: parent
                visible: wallpaperWindow.effectActive

                // Both textures are loaded before the compiled effect is shown.
                property variant source1: currentTexture
                property variant source2: nextTexture
                property real progress: wallpaperWindow.transitionProgress
                property real transitionKind: wallpaperWindow.transitionKind
                property real aspectRatio: width / Math.max(1, height)
                property real direction: wallpaperWindow.wipeDirection
                property real stripeCount: wallpaperWindow.stripeCount
                property real stripeAngle: wallpaperWindow.stripeAngle
                property vector2d centerPoint: wallpaperWindow.effectCenter

                fragmentShader: Qt.resolvedUrl(
                    "../../shaders/wallpaper_transition.frag.qsb")
            }
        }

        Timer {
            id: transitionDelay
            interval: 16
            onTriggered: transition.restart()
        }

        NumberAnimation {
            id: transition
            target: wallpaperWindow
            property: "transitionProgress"
            from: 0
            to: 1
            duration: Math.max(480,
                Math.round(ShellSettings.animationDuration * 1.7))
            easing.type: Easing.InOutCubic
            onFinished: wallpaperWindow.finishTransition()
        }
    }

    // Workspace background: Niri scales one clear copy with each workspace.
    Variants {
        model: Quickshell.screens

        WallpaperWindow {
            overviewBackdrop: false
        }
    }

    // Overview backdrop: Niri keeps this blurred copy stationary.
    Variants {
        model: Quickshell.screens

        WallpaperWindow {
            overviewBackdrop: true
        }
    }
}
