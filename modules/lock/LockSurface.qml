pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import qs.common
import qs.services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    property var context: null

    property real morphProgress: 0
    property real containerScale: 0
    property real containerRotation: 180
    property real contentOpacity: 0
    property real contentScale: 0.88
    property real backgroundBlur: 0
    property bool exiting: false

    readonly property real targetHeight:
        Math.min(height * 0.72, width * 0.92 * 9 / 16)
    readonly property real targetWidth: targetHeight * 16 / 9
    readonly property real compactSize:
        Math.min(Appearance.px(160), targetHeight)
    readonly property real compactRadius: compactSize / 4
    readonly property real panelRadius: Appearance.px(42)

    color: Appearance.layer0

    function focusAuth() {
        lockContent.forceAuthFocus();
    }

    function startExit() {
        if (exiting)
            return;

        startupAnimation.stop();
        exiting = true;
        exitAnimation.start();
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: WallpaperService.fileUrl(
            WallpaperService.currentPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.backgroundBlur
            blurMax: 64
            blurMultiplier: 1
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.withAlpha(
            Theme.palette.m3scrim, 0.48)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.focusAuth()
    }

    Connections {
        target: root.context
        ignoreUnknownSignals: true

        function onUnlockFailed() {
            root.exiting = false;
            root.focusAuth();
        }
    }

    Connections {
        target: root.lock

        function onBeginUnlock() {
            root.startExit();
        }
    }

    Rectangle {
        id: morphContainer

        anchors.centerIn: parent
        width: root.compactSize
            + (root.targetWidth - root.compactSize)
                * root.morphProgress
        height: root.compactSize
            + (root.targetHeight - root.compactSize)
                * root.morphProgress
        radius: root.compactRadius
            + (root.panelRadius - root.compactRadius)
                * root.morphProgress
        rotation: root.containerRotation
        scale: root.containerScale
        clip: true
        color: Appearance.withAlpha(Appearance.layer0, 0.96)
        border.width: 1
        border.color: Appearance.layer0Border

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Appearance.shadow
            shadowBlur: 0.72
            shadowVerticalOffset: Appearance.px(8)
        }

        Text {
            id: lockIcon

            anchors.centerIn: parent
            text: "󰌾"
            rotation: 0
            opacity: 1
            color: Appearance.layer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: root.compactSize * 0.48
            }
        }

        LockContent {
            id: lockContent

            anchors {
                fill: parent
                margins: Appearance.px(18)
            }
            context: root.context
            opacity: root.contentOpacity
            scale: root.contentScale
            visible: opacity > 0
        }
    }

    SequentialAnimation {
        id: startupAnimation

        running: false
        onFinished: {
            // 360 degrees is visually identical to zero, but normalising both
            // properties prevents the lock icon from inheriting an inverted
            // angle when it is shown again during the exit animation.
            root.containerRotation = 0;
            lockIcon.rotation = 0;
            root.focusAuth();
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "backgroundBlur"
                to: 1
                duration: Math.max(220,
                    Appearance.spatialDuration)
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "containerScale"
                to: 1
                duration: Math.max(240,
                    Appearance.spatialDuration)
                easing.type: Easing.OutBack
                easing.overshoot: 1.25
            }
            NumberAnimation {
                target: root
                property: "containerRotation"
                to: 360
                duration: Math.max(260,
                    Appearance.spatialDuration)
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockIcon
                property: "rotation"
                from: 180
                to: 0
                duration: Math.max(260,
                    Appearance.spatialDuration)
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "morphProgress"
                to: 1
                duration: Math.max(320,
                    Appearance.spatialDuration * 1.35)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.spatialCurve
            }
            NumberAnimation {
                target: lockIcon
                property: "rotation"
                from: 0
                to: 360
                duration: Appearance.spatialDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 0
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 1
                duration: Appearance.spatialDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "contentScale"
                to: 1
                duration: Appearance.spatialDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }
    }

    SequentialAnimation {
        id: exitAnimation

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "morphProgress"
                to: 0
                duration: Math.max(260,
                    Appearance.spatialDuration)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "contentScale"
                to: 0.88
                duration: Appearance.spatialDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 0
                duration: Appearance.fastDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Appearance.spatialDuration
            }
            NumberAnimation {
                target: root
                property: "backgroundBlur"
                to: 0
                duration: Appearance.spatialDuration
                easing.type: Easing.InCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: morphContainer
                property: "opacity"
                to: 0
                duration: Appearance.fastDuration
            }
            NumberAnimation {
                target: root
                property: "containerScale"
                to: 0
                duration: Appearance.fastDuration
                easing.type: Easing.InCubic
            }
        }

        onFinished: {
            if (root.context)
                root.context.finishUnlock();
            else
                root.lock.locked = false;
        }
    }

    Component.onCompleted: startupDelay.start()

    Timer {
        id: startupDelay
        interval: 16
        repeat: false
        onTriggered: startupAnimation.start()
    }
}
