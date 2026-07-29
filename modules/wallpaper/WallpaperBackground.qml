pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: wallpaperWindow

            required property ShellScreen modelData
            property string displayedSource: ""
            property string nextSource: ""
            property real transitionProgress: 0

            screen: modelData
            color: "black"
            exclusiveZone: -1

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "quickshell:wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {}

            function sourceUrl(path) {
                return path ? WallpaperService.fileUrl(path) : "";
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
                nextSource = source;
                transitionProgress = 0;
                if (nextWallpaper.status === Image.Ready)
                    transition.start();
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

            Image {
                id: currentWallpaper
                anchors.fill: parent
                source: wallpaperWindow.displayedSource
                fillMode: WallpaperService.imageFillMode
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                opacity: 1 - wallpaperWindow.transitionProgress
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
                opacity: wallpaperWindow.transitionProgress

                onStatusChanged: {
                    if (status === Image.Ready && source)
                        transition.start();
                }
            }

            NumberAnimation {
                id: transition
                target: wallpaperWindow
                property: "transitionProgress"
                from: 0
                to: 1
                duration: Math.max(180, ShellSettings.animationDuration)
                easing.type: Easing.InOutCubic
                onFinished: {
                    wallpaperWindow.displayedSource =
                        wallpaperWindow.nextSource;
                    wallpaperWindow.nextSource = "";
                    wallpaperWindow.transitionProgress = 0;
                }
            }
        }
    }
}
