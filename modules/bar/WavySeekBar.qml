pragma ComponentBehavior: Bound

import QtQuick
import qs.common

Item {
    id: root

    property real value: 0
    property bool useBarPalette: false
    property bool playing: false
    property bool seekable: true
    property bool dragging: false
    property real dragValue: 0
    readonly property real displayValue:
        dragging ? dragValue : Math.max(0, Math.min(1, value))

    signal seekRequested(real ratio)

    implicitHeight: Appearance.px(20)

    function updateDrag(mouseX) {
        dragValue = Math.max(0, Math.min(1,
            mouseX / Math.max(1, width)));
    }

    Canvas {
        id: waveCanvas

        anchors.fill: parent
        antialiasing: true
        property real amplitude: root.playing
            ? Appearance.px(2.2) : 0
        readonly property color fillColor: root.useBarPalette
            ? Appearance.barPrimary : Appearance.primary
        readonly property color trackColor:
            Appearance.withAlpha(root.useBarPalette
                ? Appearance.barSubtext : Appearance.subtext, 0.32)

        onAmplitudeChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onTrackColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Behavior on amplitude {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }

        Connections {
            target: root

            function onDisplayValueChanged() {
                waveCanvas.requestPaint();
            }

            function onPlayingChanged() {
                waveCanvas.requestPaint();
            }
        }

        FrameAnimation {
            running: root.visible && root.playing
            onTriggered: waveCanvas.requestPaint()
        }

        onPaint: {
            const context = getContext("2d");
            const lineWidth = Appearance.px(4);
            const centerY = height / 2;
            const progressX = width * root.displayValue;
            const handleGap = Appearance.px(6);
            const stopSize = Appearance.px(4);
            const phase = Date.now() / 360;
            context.clearRect(0, 0, width, height);
            context.lineCap = "round";

            const trackStart = Math.min(width - stopSize,
                progressX + handleGap);
            if (trackStart < width - stopSize * 1.5) {
                context.beginPath();
                context.strokeStyle = trackColor;
                context.lineWidth = lineWidth;
                context.moveTo(trackStart, centerY);
                context.lineTo(width - stopSize * 1.6, centerY);
                context.stroke();
            }

            context.beginPath();
            context.fillStyle = fillColor;
            context.arc(width - stopSize / 2, centerY,
                stopSize / 2, 0, Math.PI * 2);
            context.fill();

            const waveEnd = Math.max(0, progressX - handleGap);
            if (waveEnd > lineWidth / 2) {
                context.beginPath();
                context.strokeStyle = fillColor;
                context.lineWidth = lineWidth;
                for (let x = lineWidth / 2;
                        x <= waveEnd; x += 1) {
                    const y = centerY + amplitude * Math.sin(
                        6 * Math.PI * 2 * x / Math.max(1, width)
                            + phase);
                    if (x === lineWidth / 2)
                        context.moveTo(x, y);
                    else
                        context.lineTo(x, y);
                }
                context.stroke();
            }
        }
    }

    Rectangle {
        width: Appearance.px(root.dragging ? 2 : 3)
        height: Appearance.px(16)
        radius: Appearance.fullRadius
        color: root.useBarPalette
            ? Appearance.barPrimary : Appearance.primary
        x: Math.max(0, Math.min(parent.width - width,
            parent.width * root.displayValue - width / 2))
        anchors.verticalCenter: parent.verticalCenter

        Behavior on x {
            enabled: !root.dragging
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation { duration: Appearance.fastDuration }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.seekable
        hoverEnabled: true
        cursorShape: enabled
            ? (pressed ? Qt.ClosedHandCursor
                : Qt.PointingHandCursor)
            : Qt.ArrowCursor

        onPressed: mouse => {
            root.dragging = true;
            root.updateDrag(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.updateDrag(mouse.x);
        }
        onReleased: {
            root.seekRequested(root.dragValue);
            root.dragging = false;
        }
        onCanceled: root.dragging = false
    }
}
