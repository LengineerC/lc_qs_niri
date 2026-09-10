import QtQuick
import qs.common

Canvas {
    id: root
    property var samples: []
    property color lineColor: Appearance.barPrimary
    // Both network plots receive the same scale for direct comparison.
    property real maximum: 1024
    onSamplesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onMaximumChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (samples.length < 2 || width <= 0 || height <= 0)
            return;
        ctx.lineWidth = Appearance.px(2);
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.strokeStyle = lineColor;
        ctx.beginPath();
        for (let i = 0; i < samples.length; ++i) {
            const x = 2 + (width - 4) * i / (samples.length - 1);
            const y = height - 2 - (height - 4)
                * Math.max(0, Math.min(1, samples[i] / Math.max(1, maximum)));
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();
    }
}
