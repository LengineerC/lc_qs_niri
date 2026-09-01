pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.common

Canvas {
    id: root

    property var points: []
    property bool live: false
    property color waveColor: Appearance.barPrimary
    property int smoothing: 2
    property real maximumValue: 1000

    anchors.fill: parent
    opacity: live && points.length > 1 ? 1 : 0

    onPointsChanged: requestPaint()
    onLiveChanged: requestPaint()
    onWaveColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const context = getContext("2d");
        context.clearRect(0, 0, width, height);
        if (!live || points.length < 2)
            return;

        const smoothed = [];
        const count = points.length;
        for (let index = 0; index < count; index++) {
            let sum = 0;
            let samples = 0;
            for (let offset = -smoothing;
                    offset <= smoothing; offset++) {
                const sourceIndex = Math.max(0,
                    Math.min(count - 1, index + offset));
                sum += Number(points[sourceIndex]) || 0;
                samples++;
            }
            smoothed.push(sum / samples);
        }

        context.beginPath();
        context.moveTo(0, height);
        for (let index = 0; index < count; index++) {
            const x = index * width / (count - 1);
            const normalized = Math.max(0, Math.min(1,
                smoothed[index] / Math.max(1, maximumValue)));
            const y = height - normalized * height * 0.92;
            context.lineTo(x, y);
        }
        context.lineTo(width, height);
        context.closePath();
        context.fillStyle = Appearance.withAlpha(waveColor, 0.18);
        context.fill();
    }

    layer.enabled: opacity > 0
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.65
        blurMax: Appearance.px(8)
        saturation: 0.2
    }

    Behavior on opacity {
        NumberAnimation { duration: Appearance.fastDuration }
    }
}
