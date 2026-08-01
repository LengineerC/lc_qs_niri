pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

ClippingRectangle {
    id: root

    property bool active: true
    property date now: new Date()

    readonly property real secondsOfDay:
        now.getHours() * 3600
            + now.getMinutes() * 60
            + now.getSeconds()
            + now.getMilliseconds() / 1000
    readonly property real dayProgress:
        Math.max(0, Math.min(1, secondsOfDay / 86400))
    readonly property real weekProgress: {
        // JavaScript 以周日为 0；这里改为周一开始。
        const mondayBasedDay = (now.getDay() + 6) % 7;
        return (mondayBasedDay + dayProgress) / 7;
    }
    readonly property real decimalHour: secondsOfDay / 3600
    readonly property string periodLabel: {
        if (decimalHour >= 5 && decimalHour < 8)
            return I18n.tr("dawn");
        if (decimalHour >= 8 && decimalHour < 17.5)
            return I18n.tr("daytime");
        if (decimalHour >= 17.5 && decimalHour < 20)
            return I18n.tr("dusk");
        return I18n.tr("night");
    }
    readonly property string periodIcon:
        decimalHour >= 6 && decimalHour < 18 ? "󰖙" : "󰖔"
    readonly property color sceneText: "#F5F8FC"
    readonly property color sceneSubtext: "#D2DCE7"
    readonly property color starColor: "#E6F0FF"
    readonly property color cloudColor: "#F0F5F8"
    readonly property color sunColor: "#FFD27A"
    readonly property color moonColor: "#CBDCFF"
    readonly property color farLandscapeColor: "#172536"
    readonly property color nearLandscapeColor: "#101B29"

    function percentText(value): string {
        return Math.floor(Math.max(0, Math.min(1, value)) * 100)
            + "%";
    }

    Layout.fillWidth: true
    implicitHeight: Appearance.px(184)
    radius: Appearance.px(24)
    color: Appearance.layer3
    border.width: 1
    border.color: Appearance.withAlpha(Appearance.outline, 0.58)

    onNowChanged: skyCanvas.requestPaint()
    onActiveChanged: {
        if (active)
            now = new Date();
        skyCanvas.requestPaint();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }

    Canvas {
        id: skyCanvas

        anchors.fill: parent
        antialiasing: true
        property real phase: 0

        function positiveModulo(value, divisor) {
            return ((value % divisor) + divisor) % divisor;
        }

        function transition(fromColor, toColor, amount) {
            return Appearance.mix(fromColor, toColor,
                Math.max(0, Math.min(1, amount)));
        }

        function skyColors(hour) {
            // 场景使用固定的自然色相，避免壁纸强调色改变昼夜观感。
            const nightTop = "#101827";
            const nightBottom = "#1D2A3B";
            const dawnTop = "#5B6075";
            const dawnBottom = "#9B6E68";
            const dayTop = "#315F7A";
            const dayBottom = "#527985";
            const duskTop = "#66465F";
            const duskBottom = "#965A50";

            if (hour >= 5 && hour < 8) {
                const amount = (hour - 5) / 3;
                return [
                    transition(nightTop, dawnTop, amount),
                    transition(nightBottom, dawnBottom, amount)
                ];
            }
            if (hour >= 8 && hour < 10) {
                const amount = (hour - 8) / 2;
                return [
                    transition(dawnTop, dayTop, amount),
                    transition(dawnBottom, dayBottom, amount)
                ];
            }
            if (hour >= 10 && hour < 17.5)
                return [dayTop, dayBottom];
            if (hour >= 17.5 && hour < 20) {
                const amount = (hour - 17.5) / 2.5;
                return [
                    transition(dayTop, duskTop, amount),
                    transition(dayBottom, duskBottom, amount)
                ];
            }
            if (hour >= 20 && hour < 22) {
                const amount = (hour - 20) / 2;
                return [
                    transition(duskTop, nightTop, amount),
                    transition(duskBottom, nightBottom, amount)
                ];
            }
            return [nightTop, nightBottom];
        }

        function nightOpacity(hour) {
            if (hour >= 22 || hour < 5)
                return 1;
            if (hour >= 5 && hour < 7)
                return 1 - (hour - 5) / 2;
            if (hour >= 19 && hour < 22)
                return (hour - 19) / 3;
            return 0;
        }

        function drawStars(context, opacity) {
            if (opacity <= 0)
                return;

            for (let index = 0; index < 24; ++index) {
                const x = positiveModulo(
                    index * 71 + 23, Math.max(1, width));
                const y = positiveModulo(
                    index * 43 + 11, Math.max(1, height * 0.66));
                const pulse = 0.34 + 0.22 * Math.sin(
                    phase * 1.3 + index * 1.67);
                context.fillStyle = Appearance.withAlpha(
                    root.starColor,
                    opacity * pulse);
                context.beginPath();
                context.arc(x, y,
                    Appearance.px(index % 6 === 0 ? 1.3 : 0.75),
                    0, Math.PI * 2);
                context.fill();
            }
        }

        function drawCelestial(context, hour) {
            const sunVisible = hour >= 6 && hour < 18;
            const orbitProgress = sunVisible
                ? (hour - 6) / 12
                : hour >= 18 ? (hour - 18) / 12 : (hour + 6) / 12;
            const x = width * (0.1 + orbitProgress * 0.8);
            const horizon = height * 0.72;
            const y = horizon
                - Math.sin(orbitProgress * Math.PI) * height * 0.48;
            const radius = Appearance.px(sunVisible ? 11 : 9);

            const glow = context.createRadialGradient(
                x, y, 0, x, y, radius * 3.2);
            glow.addColorStop(0, Appearance.withAlpha(
                sunVisible ? root.sunColor : root.moonColor,
                sunVisible ? 0.42 : 0.3));
            glow.addColorStop(0.42, Appearance.withAlpha(
                sunVisible ? root.sunColor : root.moonColor,
                sunVisible ? 0.15 : 0.09));
            glow.addColorStop(1,
                Appearance.withAlpha(
                    sunVisible ? root.sunColor : root.moonColor, 0));
            context.fillStyle = glow;
            context.beginPath();
            context.arc(x, y, radius * 3.2, 0, Math.PI * 2);
            context.fill();

            context.fillStyle = Appearance.withAlpha(
                sunVisible ? root.sunColor : root.moonColor,
                sunVisible ? 0.86 : 0.72);
            context.beginPath();
            context.arc(x, y, radius, 0, Math.PI * 2);
            context.fill();

            if (!sunVisible) {
                context.fillStyle = Appearance.withAlpha(
                    skyColors(hour)[0], 0.98);
                context.beginPath();
                context.arc(x + radius * 0.46,
                    y - radius * 0.18,
                    radius * 0.92, 0, Math.PI * 2);
                context.fill();
            }
        }

        function drawCloud(context, centerX, centerY,
                scale, opacity) {
            const unit = Appearance.px(13) * scale;
            context.fillStyle = Appearance.withAlpha(
                root.cloudColor, opacity);
            context.beginPath();
            context.arc(centerX - unit * 0.78, centerY,
                unit * 0.64, Math.PI, Math.PI * 2);
            context.arc(centerX, centerY - unit * 0.25,
                unit * 0.9, Math.PI, Math.PI * 2);
            context.arc(centerX + unit * 0.88, centerY,
                unit * 0.58, Math.PI, Math.PI * 2);
            context.lineTo(centerX + unit * 1.46,
                centerY + unit * 0.42);
            context.lineTo(centerX - unit * 1.42,
                centerY + unit * 0.42);
            context.closePath();
            context.fill();
        }

        function drawClouds(context, hour) {
            const daylight = 1 - nightOpacity(hour) * 0.58;
            for (let index = 0; index < 3; ++index) {
                const scale = 0.78 + index * 0.16;
                const cloudWidth = Appearance.px(56) * scale;
                const travel = width + cloudWidth * 2;
                const x = positiveModulo(
                    index * travel / 3
                        + phase * (2.2 + index * 0.35),
                    travel) - cloudWidth;
                const y = height * (0.28 + index * 0.17);
                drawCloud(context, x, y, scale,
                    daylight * (0.035 + index * 0.009));
            }
        }

        function drawLandscape(context) {
            const horizon = height * 0.72;

            context.fillStyle = Appearance.withAlpha(
                root.farLandscapeColor, 0.52);
            context.beginPath();
            context.moveTo(0, height);
            context.lineTo(0, horizon + Appearance.px(7));
            context.bezierCurveTo(
                width * 0.18, horizon - Appearance.px(16),
                width * 0.34, horizon + Appearance.px(10),
                width * 0.52, horizon - Appearance.px(8));
            context.bezierCurveTo(
                width * 0.72, horizon - Appearance.px(24),
                width * 0.84, horizon + Appearance.px(7),
                width, horizon - Appearance.px(10));
            context.lineTo(width, height);
            context.closePath();
            context.fill();

            context.fillStyle = Appearance.withAlpha(
                root.nearLandscapeColor, 0.7);
            context.beginPath();
            context.moveTo(0, height);
            context.lineTo(0, horizon + Appearance.px(17));
            context.bezierCurveTo(
                width * 0.22, horizon - Appearance.px(2),
                width * 0.38, horizon + Appearance.px(25),
                width * 0.58, horizon + Appearance.px(8));
            context.bezierCurveTo(
                width * 0.76, horizon - Appearance.px(4),
                width * 0.9, horizon + Appearance.px(18),
                width, horizon + Appearance.px(4));
            context.lineTo(width, height);
            context.closePath();
            context.fill();
        }

        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);

            const hour = root.decimalHour;
            const colors = skyColors(hour);
            const gradient = context.createLinearGradient(
                0, 0, 0, height);
            gradient.addColorStop(0, colors[0]);
            gradient.addColorStop(1, colors[1]);
            context.fillStyle = gradient;
            context.fillRect(0, 0, width, height);

            drawStars(context, nightOpacity(hour));
            drawCelestial(context, hour);
            drawClouds(context, hour);
            drawLandscape(context);
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: 40
        running: root.active
        repeat: true
        onTriggered: {
            skyCanvas.phase = (skyCanvas.phase + interval / 1000)
                % 10000;
            skyCanvas.requestPaint();
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.px(8)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -Appearance.px(2)

                Text {
                    text: I18n.locale.toString(
                        root.now, ShellSettings.timeFormat)
                    color: root.sceneText
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: Appearance.px(27)
                        weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.locale.toString(
                        root.now, ShellSettings.dateFormat)
                    color: root.sceneSubtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.px(11)
                        weight: Font.Medium
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: periodRow.implicitWidth + Appearance.px(16)
                implicitHeight: Appearance.px(28)
                radius: Appearance.fullRadius
                color: Appearance.withAlpha(Appearance.layer1, 0.76)
                border.width: 1
                border.color: Appearance.withAlpha(
                    Appearance.outline, 0.45)

                RowLayout {
                    id: periodRow
                    anchors.centerIn: parent
                    spacing: Appearance.px(5)

                    Text {
                        text: root.periodIcon
                        color: Appearance.primary
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(13)
                        }
                    }

                    Text {
                        text: root.periodLabel
                        color: Appearance.layer0Text
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.px(10)
                            weight: Font.Medium
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.px(58)
            radius: Appearance.px(14)
            color: Appearance.withAlpha(Appearance.layer1, 0.76)
            border.width: 1
            border.color: Appearance.withAlpha(
                Appearance.outline, 0.38)

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(11)
                    rightMargin: Appearance.px(11)
                }
                spacing: Appearance.px(14)

                ProgressStat {
                    Layout.fillWidth: true
                    label: I18n.tr("dayProgress")
                    value: root.dayProgress
                }

                ProgressStat {
                    Layout.fillWidth: true
                    label: I18n.tr("weekProgress")
                    value: root.weekProgress
                }
            }
        }
    }

    component ProgressStat: ColumnLayout {
        id: progressStat

        required property string label
        required property real value

        spacing: Appearance.px(4)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(5)

            Text {
                Layout.fillWidth: true
                text: progressStat.label
                color: Appearance.subtext
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(9)
                    weight: Font.Medium
                }
            }

            Text {
                text: root.percentText(progressStat.value)
                color: Appearance.layer0Text
                font {
                    family: Appearance.monospaceFontFamily
                    pixelSize: Appearance.px(9)
                    weight: Font.DemiBold
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(5)
            radius: Appearance.fullRadius
            color: Appearance.withAlpha(Appearance.outline, 0.28)

            Rectangle {
                width: parent.width * Math.max(0,
                    Math.min(1, progressStat.value))
                height: parent.height
                radius: parent.radius
                color: Appearance.primary

                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.spatialDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
