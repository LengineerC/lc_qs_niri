pragma ComponentBehavior: Bound

import QtQuick
import qs.common

Item {
    id: root

    property real value: 0
    property real animatedValue: value
    property string icon: "󰍛"
    property int iconSize: 13
    property bool warning: false
    property int implicitSize: Appearance.px(24)

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Behavior on animatedValue {
        NumberAnimation {
            duration: Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }

    Canvas {
        id: ring

        anchors.fill: parent
        antialiasing: true
        readonly property color trackColor:
            Appearance.withAlpha(Appearance.subtext, 0.24)
        readonly property color progressColor: root.warning
            ? Theme.palette.m3error : Appearance.primary

        onTrackColorChanged: requestPaint()
        onProgressColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onAnimatedValueChanged() {
                ring.requestPaint();
            }
        }

        onPaint: {
            const context = getContext("2d");
            const lineWidth = Appearance.px(2);
            const centerX = width / 2;
            const centerY = height / 2;
            const radius = Math.max(1,
                Math.min(centerX, centerY) - lineWidth);
            const progress = Math.max(0,
                Math.min(1, root.animatedValue));
            context.clearRect(0, 0, width, height);
            context.lineWidth = lineWidth;
            context.lineCap = "round";

            context.beginPath();
            context.strokeStyle = trackColor;
            context.arc(centerX, centerY, radius,
                0, Math.PI * 2);
            context.stroke();

            if (progress > 0) {
                context.beginPath();
                context.strokeStyle = progressColor;
                context.arc(centerX, centerY, radius,
                    -Math.PI / 2,
                    -Math.PI / 2 + Math.PI * 2 * progress);
                context.stroke();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.warning
            ? Theme.palette.m3error : Appearance.layer0Text
        font {
            family: Appearance.iconFontFamily
            pixelSize: Appearance.px(root.iconSize)
        }
    }
}
