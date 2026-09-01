pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    // StyledPopup disables this after closing so the Canvas does no idle work.
    property bool active: visible
    readonly property color chartBrightColor:
        ShellSettings.barFrostedGlass ? "#f5ffffff" : Appearance.barPrimary
    readonly property color chartDimColor:
        ShellSettings.barFrostedGlass ? "#8affffff" : Appearance.barTertiary
    readonly property color chartSurfaceColor:
        ShellSettings.barFrostedGlass
            ? Appearance.withAlpha(Appearance.barGlassBaseColor, 0.48)
            : Appearance.barLayer3

    implicitWidth: Appearance.px(850)
    implicitHeight: contentColumn.implicitHeight
        + Appearance.px(28)

    component PanelText: Text {
        color: Appearance.barLayer1Text

        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component ModeButton: Rectangle {
        id: button

        required property string text
        property bool selected: false
        signal clicked

        implicitWidth: label.implicitWidth + Appearance.px(18)
        implicitHeight: Appearance.px(28)

        radius: Appearance.px(8)

        color: selected
            ? Appearance.barPrimaryContainer
            : area.containsMouse
                ? Appearance.barLayer1Active
                : Appearance.barLayer3

        border.width: 1
        border.color: selected
            ? Appearance.barPrimary
            : Appearance.barOutline

        PanelText {
            id: label

            anchors.centerIn: parent
            text: button.text

            color: button.selected
                ? Appearance.barPrimaryContainerText
                : Appearance.barSubtext

            font {
                pixelSize: Appearance.smallFontSize
                weight: button.selected
                    ? Font.DemiBold
                    : Font.Normal
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }
    }

    component LegendItem: RowLayout {
        id: legend

        required property color markerColor
        required property string label

        spacing: Appearance.px(5)

        Rectangle {
            Layout.preferredWidth: Appearance.px(14)
            Layout.preferredHeight: Appearance.px(3)

            radius: height / 2
            color: legend.markerColor
        }

        PanelText {
            text: legend.label
            color: Appearance.barSubtext
            font.pixelSize: Appearance.smallFontSize
        }
    }

    component MetricCard: Rectangle {
        id: metric

        required property string icon
        required property string label
        required property string value

        implicitWidth: Appearance.px(180)
        implicitHeight: Appearance.px(48)

        radius: Appearance.px(9)
        color: ShellSettings.barFrostedGlass
            ? Appearance.withAlpha(Appearance.barGlassBaseColor, 0.66)
            : Appearance.withAlpha(Appearance.barLayer2, 0.86)
        border.width: 1
        border.color: Appearance.withAlpha(Appearance.barOutline, 0.82)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(10)
                rightMargin: Appearance.px(10)
            }
            spacing: Appearance.px(9)

            Rectangle {
                Layout.preferredWidth: Appearance.px(29)
                Layout.preferredHeight: Appearance.px(29)
                Layout.alignment: Qt.AlignVCenter

                radius: Appearance.fullRadius
                color: Appearance.barPrimaryContainer

                Text {
                    anchors.centerIn: parent
                    text: metric.icon
                    color: Appearance.barPrimaryContainerText

                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(14)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PanelText {
                    Layout.fillWidth: true
                    text: metric.label
                    color: Appearance.barSubtext
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.smallFontSize
                }

                PanelText {
                    Layout.fillWidth: true
                    text: metric.value
                    color: Appearance.barLayer0Text
                    elide: Text.ElideRight

                    font {
                        pixelSize: Appearance.fontSize
                        weight: Font.DemiBold
                    }
                }
            }
        }
    }

    /*
     * 当前天气的轻量动态背景。所有粒子位置都由时间和固定种子计算，
     * 因此天气面板重新显示时不会出现随机闪烁。
     */
    component WeatherBackdrop: Canvas {
        id: backdrop

        required property int weatherCode
        required property bool daytime
        required property bool animationsActive

        property real phase: 0

        readonly property string weatherKind: {
            const code = Number(weatherCode);
            if (code === 0)
                return "clear";
            if (code === 1 || code === 2)
                return "partlyCloudy";
            if (code === 3)
                return "cloudy";
            if (code === 45 || code === 48)
                return "fog";
            if (code >= 51 && code <= 57)
                return "drizzle";
            if ((code >= 61 && code <= 67)
                    || (code >= 80 && code <= 82))
                return "rain";
            if ((code >= 71 && code <= 77)
                    || code === 85 || code === 86)
                return "snow";
            if (code >= 95)
                return "thunder";
            return "cloudy";
        }

        antialiasing: true

        function positiveModulo(value, divisor) {
            return ((value % divisor) + divisor) % divisor;
        }

        function roundedPath(context, x, y, pathWidth,
                pathHeight, radius) {
            const safeRadius = Math.min(radius,
                pathWidth / 2, pathHeight / 2);

            context.beginPath();
            context.moveTo(x + safeRadius, y);
            context.lineTo(x + pathWidth - safeRadius, y);
            context.quadraticCurveTo(
                x + pathWidth, y,
                x + pathWidth, y + safeRadius);
            context.lineTo(x + pathWidth,
                y + pathHeight - safeRadius);
            context.quadraticCurveTo(
                x + pathWidth, y + pathHeight,
                x + pathWidth - safeRadius, y + pathHeight);
            context.lineTo(x + safeRadius, y + pathHeight);
            context.quadraticCurveTo(
                x, y + pathHeight,
                x, y + pathHeight - safeRadius);
            context.lineTo(x, y + safeRadius);
            context.quadraticCurveTo(x, y, x + safeRadius, y);
            context.closePath();
        }

        function drawCelestial(context) {
            const centerX = width * 0.19;
            const centerY = height * 0.34;
            const radius = Math.min(width, height) * 0.105;

            if (daytime) {
                context.save();
                context.translate(centerX, centerY);
                context.rotate(phase * 0.045);
                context.strokeStyle = Appearance.withAlpha(
                    Appearance.barPrimary, 0.18);
                context.lineWidth = Appearance.px(2);
                context.lineCap = "round";

                for (let index = 0; index < 12; ++index) {
                    const angle = Math.PI * 2 * index / 12;
                    context.beginPath();
                    context.moveTo(
                        Math.cos(angle) * radius * 1.45,
                        Math.sin(angle) * radius * 1.45);
                    context.lineTo(
                        Math.cos(angle) * radius * 1.85,
                        Math.sin(angle) * radius * 1.85);
                    context.stroke();
                }
                context.restore();

                const glow = context.createRadialGradient(
                    centerX, centerY, 0,
                    centerX, centerY, radius * 2.4);
                glow.addColorStop(0, Appearance.withAlpha(
                    Appearance.barPrimary, 0.22));
                glow.addColorStop(0.42, Appearance.withAlpha(
                    Appearance.barPrimary, 0.09));
                glow.addColorStop(1, Appearance.withAlpha(
                    Appearance.barPrimary, 0));
                context.fillStyle = glow;
                context.beginPath();
                context.arc(centerX, centerY,
                    radius * 2.4, 0, Math.PI * 2);
                context.fill();
            } else {
                for (let index = 0; index < 18; ++index) {
                    const x = positiveModulo(
                        index * 83 + 29, Math.max(1, width));
                    const y = positiveModulo(
                        index * 47 + 17, Math.max(1, height * 0.72));
                    const pulse = 0.35 + 0.25 * Math.sin(
                        phase * 1.4 + index * 1.7);
                    context.fillStyle = Appearance.withAlpha(
                        Appearance.barPrimary, pulse);
                    context.beginPath();
                    context.arc(x, y,
                        Appearance.px(index % 5 === 0 ? 1.3 : 0.8),
                        0, Math.PI * 2);
                    context.fill();
                }

                context.fillStyle = Appearance.withAlpha(
                    Appearance.barPrimary, 0.2);
                context.beginPath();
                const moonRadius = radius * 1.12;
                context.moveTo(centerX + moonRadius * 0.32,
                    centerY - moonRadius * 0.92);
                context.bezierCurveTo(
                    centerX - moonRadius * 0.42,
                    centerY - moonRadius * 1.02,
                    centerX - moonRadius * 0.9,
                    centerY - moonRadius * 0.48,
                    centerX - moonRadius * 0.9,
                    centerY);
                context.bezierCurveTo(
                    centerX - moonRadius * 0.9,
                    centerY + moonRadius * 0.48,
                    centerX - moonRadius * 0.42,
                    centerY + moonRadius * 1.02,
                    centerX + moonRadius * 0.32,
                    centerY + moonRadius * 0.92);
                context.bezierCurveTo(
                    centerX - moonRadius * 0.34,
                    centerY + moonRadius * 0.48,
                    centerX - moonRadius * 0.34,
                    centerY - moonRadius * 0.48,
                    centerX + moonRadius * 0.32,
                    centerY - moonRadius * 0.92);
                context.closePath();
                context.fill();
            }
        }

        function drawCloud(context, centerX, centerY,
                cloudScale, alpha) {
            const unit = Appearance.px(18) * cloudScale;
            context.fillStyle = Appearance.withAlpha(
                Appearance.barLayer0Text, alpha);
            context.beginPath();
            context.arc(centerX - unit * 0.8, centerY,
                unit * 0.72, Math.PI, Math.PI * 2);
            context.arc(centerX, centerY - unit * 0.28,
                unit, Math.PI, Math.PI * 2);
            context.arc(centerX + unit * 0.95, centerY,
                unit * 0.68, Math.PI, Math.PI * 2);
            context.lineTo(centerX + unit * 1.63,
                centerY + unit * 0.48);
            context.lineTo(centerX - unit * 1.52,
                centerY + unit * 0.48);
            context.closePath();
            context.fill();
        }

        function drawCloudLayer(context, dense) {
            // 每条纵向轨道只放一朵云，避免不同速度的云彼此追上。
            const count = dense ? 3 : 2;
            const laneHeights = dense
                ? [0.2, 0.48, 0.75]
                : [0.26, 0.66];
            for (let index = 0; index < count; ++index) {
                const scale = dense
                    ? 0.78 + index * 0.16
                    : 0.82 + index * 0.2;
                const cloudWidth = Appearance.px(78) * scale;
                const travelWidth = width + cloudWidth * 2;
                const x = positiveModulo(
                    index * travelWidth / count
                        + phase * (3.2 + index * 0.38),
                    travelWidth) - cloudWidth;
                const y = height * laneHeights[index];
                drawCloud(context, x, y, scale,
                    dense ? 0.068 : 0.052);
            }
        }

        function drawRain(context, lightRain) {
            const count = lightRain ? 24 : 42;
            context.strokeStyle = Appearance.withAlpha(
                Appearance.barPrimary, lightRain ? 0.22 : 0.32);
            context.lineWidth = Appearance.px(1.25);
            context.lineCap = "round";

            for (let index = 0; index < count; ++index) {
                const x = positiveModulo(
                    index * 67 + 19, Math.max(1, width + 24)) - 12;
                const speed = lightRain ? 62 : 105;
                const y = positiveModulo(
                    index * 43 + phase * speed,
                    height + Appearance.px(28)) - Appearance.px(20);
                const length = Appearance.px(
                    lightRain ? 7 : 11 + index % 4);
                context.beginPath();
                context.moveTo(x, y);
                context.lineTo(x - length * 0.22, y + length);
                context.stroke();
            }
        }

        function drawSnow(context) {
            for (let index = 0; index < 30; ++index) {
                const drift = Math.sin(
                    phase * 0.85 + index * 1.31)
                    * Appearance.px(8);
                const x = positiveModulo(
                    index * 79 + 23, Math.max(1, width)) + drift;
                const y = positiveModulo(
                    index * 37 + phase * (16 + index % 5),
                    height + Appearance.px(16)) - Appearance.px(8);
                const radius = Appearance.px(1 + index % 3 * 0.45);
                context.fillStyle = Appearance.withAlpha(
                    Appearance.barLayer0Text, 0.25 + (index % 4) * 0.04);
                context.beginPath();
                context.arc(x, y, radius, 0, Math.PI * 2);
                context.fill();
            }
        }

        function drawFogWisp(context, centerX, centerY,
                wispWidth, thickness, alpha) {
            const left = centerX - wispWidth / 2;
            const right = centerX + wispWidth / 2;
            const gradient = context.createLinearGradient(
                left, centerY, right, centerY);
            gradient.addColorStop(0,
                Appearance.withAlpha(Appearance.barLayer0Text, 0));
            gradient.addColorStop(0.18,
                Appearance.withAlpha(Appearance.barLayer0Text,
                    alpha * 0.62));
            gradient.addColorStop(0.5,
                Appearance.withAlpha(Appearance.barLayer0Text, alpha));
            gradient.addColorStop(0.82,
                Appearance.withAlpha(Appearance.barLayer0Text,
                    alpha * 0.62));
            gradient.addColorStop(1,
                Appearance.withAlpha(Appearance.barLayer0Text, 0));

            context.fillStyle = gradient;
            context.beginPath();
            context.moveTo(left, centerY);
            context.bezierCurveTo(
                left + wispWidth * 0.23,
                centerY - thickness * 0.72,
                left + wispWidth * 0.7,
                centerY + thickness * 0.32,
                right, centerY - thickness * 0.18);
            context.bezierCurveTo(
                left + wispWidth * 0.72,
                centerY + thickness * 0.9,
                left + wispWidth * 0.28,
                centerY + thickness * 0.55,
                left, centerY);
            context.closePath();
            context.fill();
        }

        function drawFog(context) {
            const count = 4;
            for (let index = 0; index < count; ++index) {
                const wispWidth = width * (0.48 + index % 2 * 0.12);
                const travelWidth = width + wispWidth;
                const direction = index % 2 === 0 ? 1 : -1;
                const rawPosition = index * travelWidth / count
                    + direction * phase * (2.2 + index * 0.28);
                const centerX = positiveModulo(
                    rawPosition, travelWidth) - wispWidth / 2;
                const centerY = height * (0.25 + index * 0.16)
                    + Math.sin(phase * 0.18 + index)
                        * Appearance.px(3);
                const thickness = Appearance.px(13 + index % 2 * 4);

                drawFogWisp(context, centerX, centerY,
                    wispWidth, thickness, 0.065 + index * 0.008);
                // 在循环边缘补绘同一雾团，避免突然整片消失。
                drawFogWisp(context, centerX + travelWidth,
                    centerY, wispWidth, thickness,
                    0.065 + index * 0.008);
            }
        }

        function drawLightning(context) {
            const cycle = positiveModulo(phase, 6.4);
            if (cycle > 0.16)
                return;

            const strength = Math.sin(cycle / 0.16 * Math.PI);
            context.fillStyle = Appearance.withAlpha(
                Appearance.barPrimary, 0.055 * strength);
            context.fillRect(0, 0, width, height);

            context.strokeStyle = Appearance.withAlpha(
                Appearance.barPrimary, 0.55 * strength);
            context.lineWidth = Appearance.px(1.7);
            context.lineJoin = "round";
            context.beginPath();
            context.moveTo(width * 0.72, height * 0.14);
            context.lineTo(width * 0.67, height * 0.43);
            context.lineTo(width * 0.72, height * 0.43);
            context.lineTo(width * 0.65, height * 0.78);
            context.stroke();
        }

        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);

            context.save();
            roundedPath(context, 0, 0, width, height,
                Math.max(0, Appearance.smallRadius - 1));
            context.clip();

            const baseStart = Appearance.mix(
                Appearance.barLayer3,
                daytime ? Appearance.barPrimaryContainer
                    : Appearance.layer0,
                daytime ? 0.22 : 0.34);
            const baseEnd = Appearance.mix(
                Appearance.barLayer3,
                weatherKind === "thunder"
                    ? Appearance.barTertiary
                    : Appearance.barPrimaryContainer,
                weatherKind === "thunder" ? 0.14 : 0.1);
            const gradient = context.createLinearGradient(
                0, 0, width, height);
            gradient.addColorStop(0, baseStart);
            gradient.addColorStop(1, baseEnd);
            context.fillStyle = gradient;
            context.fillRect(0, 0, width, height);

            if (weatherKind === "clear"
                    || weatherKind === "partlyCloudy")
                drawCelestial(context);

            if (weatherKind === "partlyCloudy"
                    || weatherKind === "cloudy"
                    || weatherKind === "drizzle"
                    || weatherKind === "rain"
                    || weatherKind === "snow"
                    || weatherKind === "thunder") {
                drawCloudLayer(context,
                    weatherKind !== "partlyCloudy");
            }

            if (weatherKind === "fog")
                drawFog(context);
            else if (weatherKind === "drizzle")
                drawRain(context, true);
            else if (weatherKind === "rain")
                drawRain(context, false);
            else if (weatherKind === "snow")
                drawSnow(context);
            else if (weatherKind === "thunder") {
                drawRain(context, false);
                drawLightning(context);
            }

            context.restore();
        }

        onWeatherCodeChanged: requestPaint()
        onDaytimeChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Timer {
            interval: 40
            repeat: true
            running: backdrop.visible
                && backdrop.animationsActive
                && WeatherService.ready
            onTriggered: {
                backdrop.phase += interval / 1000;
                backdrop.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
    }

    /*
     * 逐小时图表
     *
     * mode:
     *   0：气温 + 体感温度
     *   1：降雨概率 + 湿度
     *   2：风速
     */
    component HourlyChart: Item {
        id: hourlyChart

        property int mode: 0
        property int maximumPoints: 10
        property var sourceData: WeatherService.hourlyForecast

        readonly property real plotLeft:
            leftPadding + Appearance.px(8)

        readonly property real plotRight:
            width - rightPadding - Appearance.px(8)

        readonly property real plotTop:
            topPadding

        readonly property real plotBottom:
            height - bottomPadding

        function pointX(index, count) {
            if (count <= 1)
                return (plotLeft + plotRight) / 2;

            return plotLeft
                + index * (plotRight - plotLeft) / (count - 1);
        }

        readonly property var chartData:
            Array.isArray(sourceData)
                ? sourceData.slice(0, maximumPoints)
                : []

        readonly property real leftPadding: Appearance.px(42)
        readonly property real rightPadding: Appearance.px(12)
        readonly property real topPadding: Appearance.px(21)
        readonly property real bottomPadding: Appearance.px(48)

        readonly property color primaryLine:
            root.chartBrightColor
        readonly property color secondaryLine:
            root.chartDimColor

        function repaint() {
            chartCanvas.requestPaint();
        }

        onModeChanged: repaint()
        onChartDataChanged: repaint()
        onWidthChanged: repaint()
        onHeightChanged: repaint()
        onVisibleChanged: {
            if (visible)
                repaint();
        }

        Canvas {
            id: chartCanvas

            anchors.fill: parent
            antialiasing: true

            function xFor(index, count) {
                return hourlyChart.pointX(index, count);
            }

            function yFor(value, minimum, maximum, top, bottom) {
                const ratio = (value - minimum)
                    / Math.max(0.0001, maximum - minimum);

                return bottom - ratio * (bottom - top);
            }

            function rangeFor(values, minimumPadding) {
                let minimum = Infinity;
                let maximum = -Infinity;

                for (let index = 0;
                        index < values.length; ++index) {
                    const value = Number(values[index]);

                    if (!Number.isFinite(value))
                        continue;

                    minimum = Math.min(minimum, value);
                    maximum = Math.max(maximum, value);
                }

                if (!Number.isFinite(minimum)
                        || !Number.isFinite(maximum)) {
                    return {
                        minimum: 0,
                        maximum: 1
                    };
                }

                if (minimum === maximum) {
                    minimum -= 1;
                    maximum += 1;
                }

                const padding = Math.max(
                    minimumPadding,
                    (maximum - minimum) * 0.16
                );

                return {
                    minimum: minimum - padding,
                    maximum: maximum + padding
                };
            }

            function drawGrid(context, minimum, maximum,
                    left, right, top, bottom, unit="") {
                const rowCount = 4;

                context.lineWidth = 1;
                context.strokeStyle = Appearance.withAlpha(
                    Appearance.barOutline, 0.36);
                context.fillStyle = Appearance.barSubtext;
                context.font =
                    Appearance.smallFontSize
                    + "px " + Appearance.fontFamily;
                context.textAlign = "right";
                context.textBaseline = "middle";

                for (let index = 0;
                        index <= rowCount; ++index) {
                    const ratio = index / rowCount;
                    const y = top + ratio * (bottom - top);
                    const value = maximum
                        - ratio * (maximum - minimum);

                    context.beginPath();
                    context.moveTo(left, y);
                    context.lineTo(right, y);
                    context.stroke();

                    context.fillText(
                        String(Math.round(value) + unit),
                        left - Appearance.px(7),
                        y
                    );
                }
            }

            function drawLine(context, values, color,
                minimum, maximum,
                left, right, top, bottom,
                suffix, labelOffset) {
                if (!values || values.length === 0)
                    return;

                context.lineWidth = Appearance.px(2);
                context.lineJoin = "round";
                context.lineCap = "round";
                context.strokeStyle = color;

                let pathStarted = false;

                context.beginPath();

                for (let index = 0; index < values.length; ++index) {
                    const value = Number(values[index]);

                    if (!Number.isFinite(value))
                        continue;

                    const x = xFor(index, values.length);
                    const y = yFor(
                        value,
                        minimum,
                        maximum,
                        top,
                        bottom
                    );

                    if (!pathStarted) {
                        context.moveTo(x, y);
                        pathStarted = true;
                    } else {
                        context.lineTo(x, y);
                    }
                }

                if (pathStarted)
                    context.stroke();

                const fontSize = Appearance.smallFontSize;

                context.fillStyle = color;
                context.font = fontSize
                    + "px " + Appearance.fontFamily;
                context.textBaseline = "middle";

                for (let index = 0; index < values.length; ++index) {
                    const value = Number(values[index]);

                    if (!Number.isFinite(value))
                        continue;

                    const x = xFor(index, values.length);
                    const y = yFor(
                        value,
                        minimum,
                        maximum,
                        top,
                        bottom
                    );

                    context.beginPath();
                    context.arc(
                        x,
                        y,
                        Appearance.px(3.2),
                        0,
                        Math.PI * 2
                    );
                    context.fill();

                    /*
                    * 防止第一个和最后一个标签超出图表：
                    *
                    * 第一个向右展开；
                    * 最后一个向左展开；
                    * 中间标签居中。
                    */
                    if (index === 0)
                        context.textAlign = "left";
                    else if (index === values.length - 1)
                        context.textAlign = "right";
                    else
                        context.textAlign = "center";

                    const rawLabelY = y + labelOffset;
                    const labelY = Math.max(
                        top + fontSize / 2,
                        Math.min(
                            bottom - fontSize / 2,
                            rawLabelY
                        )
                    );

                    context.fillText(
                        String(Math.round(value))
                            + String(suffix ?? ""),
                        x,
                        labelY
                    );
                }
            }

            onPaint: {
                const context = getContext("2d");

                context.clearRect(0, 0, width, height);

                const data = hourlyChart.chartData;
                if (data.length === 0)
                    return;

                const left = hourlyChart.plotLeft - 3;
                const right = hourlyChart.plotRight - 3;
                const top = hourlyChart.plotTop;
                const bottom = hourlyChart.plotBottom;

                const upperLabelOffset = -Appearance.px(12);
                const lowerLabelOffset = Appearance.px(13);

                if (hourlyChart.mode === 0) {
                    const temperatures = data.map(item =>
                        Number(item.temperature));

                    const apparent = data.map(item =>
                        Number(item.apparentTemperature));

                    const range = rangeFor(
                        temperatures.concat(apparent),
                        2
                    );

                    drawGrid(
                        context,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "°C"
                    );

                    drawLine(
                        context,
                        temperatures,
                        hourlyChart.primaryLine,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "°C",
                        lowerLabelOffset
                    );

                    drawLine(
                        context,
                        apparent,
                        hourlyChart.secondaryLine,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "°C",
                        lowerLabelOffset
                    );
                } else if (hourlyChart.mode === 1) {
                    const precipitation = data.map(item =>
                        Math.max(
                            0,
                            Math.min(
                                100,
                                Number(
                                    item.precipitationProbability
                                )
                            )
                        )
                    );

                    const humidity = data.map(item =>
                        Math.max(
                            0,
                            Math.min(
                                100,
                                Number(item.humidity)
                            )
                        )
                    );

                    drawGrid(
                        context,
                        0,
                        100,
                        left,
                        right,
                        top,
                        bottom,
                        "%"
                    );

                    // 降雨概率折线
                    drawLine(
                        context,
                        precipitation,
                        hourlyChart.primaryLine,
                        0,
                        100,
                        left,
                        right,
                        top,
                        bottom,
                        "%",
                        lowerLabelOffset
                    );

                    // 湿度折线
                    drawLine(
                        context,
                        humidity,
                        hourlyChart.secondaryLine,
                        0,
                        100,
                        left,
                        right,
                        top,
                        bottom,
                        "%",
                        lowerLabelOffset
                    );
                } else {
                    const wind = data.map(item =>
                        Number(item.windSpeed));

                    const range = rangeFor(wind, 1);

                    range.minimum = Math.max(
                        0,
                        range.minimum
                    );

                    drawGrid(
                        context,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "km/h"
                    );

                    // 风速折线并标注数值
                    drawLine(
                        context,
                        wind,
                        hourlyChart.primaryLine,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "km/h",
                        lowerLabelOffset
                    );
                }
            }

            Component.onCompleted: requestPaint()
        }

        Item {
            id: hourlyLabels

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            height: hourlyChart.bottomPadding

            Repeater {
                model: hourlyChart.chartData

                delegate: Item {
                    required property var modelData
                    required property int index

                    width: Appearance.px(64)
                    height: hourlyLabels.height

                    x: hourlyChart.pointX(
                        index,
                        hourlyChart.chartData.length
                    ) - width / 2

                    Column {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                            topMargin: Appearance.px(7)
                        }

                        spacing: Appearance.px(2)

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: WeatherService.icon(
                                modelData.weatherCode,
                                modelData.isDay
                            )

                            color: index === 0
                                ? Appearance.barPrimary
                                : Appearance.barSubtext

                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(15)
                            }
                        }

                        PanelText {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: index === 0
                                ? "现在"
                                : WeatherService.timeFromIso(
                                    modelData.time)

                            color: index === 0
                                ? Appearance.barPrimary
                                : Appearance.barSubtext

                            font.pixelSize:
                                Appearance.smallFontSize
                        }
                    }
                }
            }
        }
    }

    /*
     * 未来七天图表
     *
     * mode:
     *   0：最高、最低气温
     *   1：降雨概率
     */
    component DailyChart: Item {
        id: dailyChart

        property int mode: 0
        property var sourceData: WeatherService.dailyForecast
        readonly property real plotLeft:
            leftPadding + Appearance.px(8)

        readonly property real plotRight:
            width - rightPadding - Appearance.px(8)

        readonly property real plotTop:
            topPadding

        readonly property real plotBottom:
            height - bottomPadding

        function pointX(index, count) {
            if (count <= 1)
                return (plotLeft + plotRight) / 2;

            return plotLeft
                + index * (plotRight - plotLeft) / (count - 1);
        }

        readonly property var chartData:
            Array.isArray(sourceData)
                ? sourceData.slice(0, 7)
                : []

        readonly property real leftPadding: Appearance.px(42)
        readonly property real rightPadding: Appearance.px(12)
        readonly property real topPadding: Appearance.px(21)
        readonly property real bottomPadding: Appearance.px(50)

        readonly property color maximumColor:
            root.chartBrightColor
        readonly property color minimumColor:
            root.chartDimColor

        function repaint() {
            chartCanvas.requestPaint();
        }

        onModeChanged: repaint()
        onChartDataChanged: repaint()
        onWidthChanged: repaint()
        onHeightChanged: repaint()
        onVisibleChanged: {
            if (visible)
                repaint();
        }

        Canvas {
            id: chartCanvas

            anchors.fill: parent
            antialiasing: true

            function xFor(index, count) {
                return dailyChart.pointX(index, count);
            }

            function yFor(value, minimum, maximum, top, bottom) {
                const ratio = (value - minimum)
                    / Math.max(0.0001, maximum - minimum);

                return bottom - ratio * (bottom - top);
            }

            function rangeFor(values) {
                let minimum = Infinity;
                let maximum = -Infinity;

                for (let index = 0;
                        index < values.length; ++index) {
                    const value = Number(values[index]);

                    if (!Number.isFinite(value))
                        continue;

                    minimum = Math.min(minimum, value);
                    maximum = Math.max(maximum, value);
                }

                if (!Number.isFinite(minimum)
                        || !Number.isFinite(maximum)) {
                    return {
                        minimum: 0,
                        maximum: 1
                    };
                }

                if (minimum === maximum) {
                    minimum -= 1;
                    maximum += 1;
                }

                const padding = Math.max(
                    2,
                    (maximum - minimum) * 0.18
                );

                return {
                    minimum: minimum - padding,
                    maximum: maximum + padding
                };
            }

            function drawGrid(context, minimum, maximum,
                    left, right, top, bottom, unit="") {
                const rowCount = 4;

                context.lineWidth = 1;
                context.strokeStyle = Appearance.withAlpha(
                    Appearance.barOutline, 0.36);
                context.fillStyle = Appearance.barSubtext;
                context.font =
                    Appearance.smallFontSize
                    + "px " + Appearance.fontFamily;
                context.textAlign = "right";
                context.textBaseline = "middle";

                for (let index = 0;
                        index <= rowCount; ++index) {
                    const ratio = index / rowCount;
                    const y = top + ratio * (bottom - top);
                    const value = maximum
                        - ratio * (maximum - minimum);

                    context.beginPath();
                    context.moveTo(left, y);
                    context.lineTo(right, y);
                    context.stroke();

                    context.fillText(
                        String(Math.round(value) + unit),
                        left - Appearance.px(7),
                        y
                    );
                }
            }

            function drawLine(context, values, color,
                    minimum, maximum,
                    left, right, top, bottom,
                    suffix, labelOffset) {
                if (!values || values.length === 0)
                    return;

                context.lineWidth = Appearance.px(2.2);
                context.lineJoin = "round";
                context.lineCap = "round";
                context.strokeStyle = color;

                let pathStarted = false;

                context.beginPath();

                for (let index = 0; index < values.length; ++index) {
                    const value = Number(values[index]);

                    if (!Number.isFinite(value))
                        continue;

                    const x = xFor(index, values.length);
                    const y = yFor(
                        value,
                        minimum,
                        maximum,
                        top,
                        bottom
                    );

                    if (!pathStarted) {
                        context.moveTo(x, y);
                        pathStarted = true;
                    } else {
                        context.lineTo(x, y);
                    }
                }

                if (pathStarted)
                    context.stroke();

                const fontSize = Appearance.smallFontSize;

                context.fillStyle = color;
                context.textBaseline = "middle";
                context.font = fontSize
                    + "px " + Appearance.fontFamily;

                for (let index = 0; index < values.length; ++index) {
                    const value = Number(values[index]);

                    if (!Number.isFinite(value))
                        continue;

                    const x = xFor(index, values.length);
                    const y = yFor(
                        value,
                        minimum,
                        maximum,
                        top,
                        bottom
                    );

                    context.beginPath();
                    context.arc(
                        x,
                        y,
                        Appearance.px(3.4),
                        0,
                        Math.PI * 2
                    );
                    context.fill();

                    if (index === 0)
                        context.textAlign = "left";
                    else if (index === values.length - 1)
                        context.textAlign = "right";
                    else
                        context.textAlign = "center";

                    const rawLabelY = y + labelOffset;
                    const labelY = Math.max(
                        top + fontSize / 2,
                        Math.min(
                            bottom - fontSize / 2,
                            rawLabelY
                        )
                    );

                    context.fillText(
                        String(Math.round(value))
                            + String(suffix ?? ""),
                        x,
                        labelY
                    );
                }
            }

            onPaint: {
                const context = getContext("2d");

                context.clearRect(0, 0, width, height);

                const data = dailyChart.chartData;
                if (data.length === 0)
                    return;

                const left = dailyChart.plotLeft - 3;
                const right = dailyChart.plotRight - 3;
                const top = dailyChart.plotTop;
                const bottom = dailyChart.plotBottom;

                if (dailyChart.mode === 0) {
                    const maximumValues = data.map(item =>
                        Number(item.temperatureMax));
                    const minimumValues = data.map(item =>
                        Number(item.temperatureMin));

                    const range = rangeFor(
                        maximumValues.concat(minimumValues));

                    drawGrid(
                        context,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "°C"
                    );

                    drawLine(
                        context,
                        maximumValues,
                        dailyChart.maximumColor,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "°C",
                        Appearance.px(13)
                    );

                    drawLine(
                        context,
                        minimumValues,
                        dailyChart.minimumColor,
                        range.minimum,
                        range.maximum,
                        left,
                        right,
                        top,
                        bottom,
                        "°C",
                        Appearance.px(13)
                    );
                } else {
                    const precipitation = data.map(item =>
                        Math.max(
                            0,
                            Math.min(
                                100,
                                Number(
                                    item.precipitationProbability
                                )
                            )
                        )
                    );

                    drawGrid(
                        context,
                        0,
                        100,
                        left,
                        right,
                        top,
                        bottom,
                        "%"
                    );

                    drawLine(
                        context,
                        precipitation,
                        dailyChart.maximumColor,
                        0,
                        100,
                        left,
                        right,
                        top,
                        bottom,
                        "%",
                        Appearance.px(13)
                    );
                }
            }

            Component.onCompleted: requestPaint()
        }

        Item {
            id: dayLabels

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            height: dailyChart.bottomPadding

            Repeater {
                model: dailyChart.chartData

                delegate: Item {
                    required property var modelData
                    required property int index

                    width: Appearance.px(70)
                    height: dayLabels.height

                    x: dailyChart.pointX(
                        index,
                        dailyChart.chartData.length
                    ) - width / 2

                    Column {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                            topMargin: Appearance.px(7)
                        }

                        spacing: Appearance.px(2)

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: WeatherService.icon(
                                modelData.weatherCode, 1)

                            color: index === 0
                                ? Appearance.barPrimary
                                : Appearance.barSubtext

                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(15)
                            }
                        }

                        PanelText {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: index === 0
                                ? "今天"
                                : WeatherService.dayName(
                                    modelData.date)

                            color: index === 0
                                ? Appearance.barPrimary
                                : Appearance.barSubtext

                            font.pixelSize:
                                Appearance.smallFontSize
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Appearance.px(14)
        }

        spacing: Appearance.px(10)

        PopupHeader {
            useBarPalette: true
            icon: WeatherService.currentIcon
            iconSize: Appearance.px(22)
            title: I18n.tr("weather")
            dividerSpacing: Appearance.px(10)
            onCloseClicked: root.closeRequested()

            Rectangle {
                implicitWidth: Appearance.px(30)
                implicitHeight: Appearance.px(30)
                radius: Appearance.fullRadius
                color: refreshArea.containsMouse
                    ? Appearance.barLayer1Active : "transparent"
                opacity: WeatherService.loading ? 0.55 : 1

                Text {
                    id: refreshIcon

                    anchors.centerIn: parent
                    text: "󰑐"
                    color: Appearance.barSubtext
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(15)
                    }

                    RotationAnimator {
                        target: refreshIcon
                        running: WeatherService.loading
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    enabled: !WeatherService.loading
                    hoverEnabled: true
                    cursorShape: enabled
                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: WeatherService.refresh()
                }
            }
        }


        /*
         * 当前天气
         */
        Rectangle {
            id: currentWeatherCard

            Layout.fillWidth: true
            implicitHeight: Appearance.px(190)

            radius: Appearance.smallRadius
            color: Appearance.barLayer3
            border.width: 1
            border.color: Appearance.barOutline

            WeatherBackdrop {
                anchors {
                    fill: parent
                    margins: 1
                }

                visible: WeatherService.ready
                weatherCode: Number(
                    WeatherService.current.weatherCode ?? -1)
                daytime: Number(
                    WeatherService.current.isDay ?? 1) !== 0
                animationsActive: root.active
            }

            RowLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(14)
                }

                visible: WeatherService.ready
                spacing: Appearance.px(16)

                RowLayout {
                    Layout.preferredWidth: Appearance.px(245)
                    Layout.minimumWidth: Appearance.px(225)
                    Layout.maximumWidth: Appearance.px(270)
                    Layout.fillHeight: true

                    spacing: Appearance.px(13)

                    Rectangle {
                        Layout.preferredWidth: Appearance.px(82)
                        Layout.preferredHeight: Appearance.px(82)
                        Layout.alignment: Qt.AlignVCenter

                        radius: Appearance.fullRadius
                        color: Appearance.barPrimaryContainer

                        Text {
                            anchors.centerIn: parent
                            text: WeatherService.currentIcon
                            color: Appearance.barPrimaryContainerText

                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(46)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Appearance.px(2)

                        PanelText {
                            text: WeatherService.currentTemperature
                            color: Appearance.barLayer0Text

                            font {
                                pixelSize: Appearance.px(31)
                                weight: Font.Medium
                            }
                        }

                        PanelText {
                            Layout.fillWidth: true

                            text: WeatherService.description(
                                WeatherService.current.weatherCode)

                            color: Appearance.barLayer0Text
                            elide: Text.ElideRight

                            font {
                                pixelSize: Appearance.fontSize + 1
                                weight: Font.DemiBold
                            }
                        }

                        PanelText {
                            Layout.fillWidth: true

                            text: I18n.tr("feelsLike") + " "
                                + WeatherService.formatTemperature(
                                    WeatherService.current
                                        .apparentTemperature)

                            color: Appearance.barSubtext
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.smallFontSize
                        }
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.topMargin: Appearance.px(2)
                    Layout.bottomMargin: Appearance.px(2)

                    implicitWidth: 1
                    color: Appearance.barOutline
                    opacity: 0.65
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    columns: 2
                    rowSpacing: Appearance.px(8)
                    columnSpacing: Appearance.px(8)
                    uniformCellWidths: true
                    uniformCellHeights: true

                    MetricCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        icon: "󰖎"
                        label: I18n.tr("humidity")
                        value: WeatherService.formatPercent(
                            WeatherService.current.humidity)
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        icon: "󰖝"
                        label: I18n.tr("windSpeed")
                        value: WeatherService.formatWind(
                            WeatherService.current.windSpeed)
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        icon: "󰒋"
                        label: I18n.tr("pressure")
                        value: WeatherService.formatPressure(
                            WeatherService.current.pressure)
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        icon: "󰖗"
                        label: I18n.tr("precipitation")
                        value: WeatherService.formatPercent(
                            WeatherService.current
                                .precipitationProbability)
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        icon: "󰖜"
                        label: I18n.tr("sunrise")
                        value: WeatherService.timeFromIso(
                            WeatherService.current.sunrise)
                    }

                    MetricCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        icon: "󰖛"
                        label: I18n.tr("sunset")
                        value: WeatherService.timeFromIso(
                            WeatherService.current.sunset)
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: !WeatherService.ready
                spacing: Appearance.px(8)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: WeatherService.loading ? "󰔟" : "󰅚"
                    color: Appearance.barPrimary

                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(28)
                    }
                }

                PanelText {
                    text: WeatherService.loading
                        ? I18n.tr("weatherLoading")
                        : I18n.tr("weatherUnavailable")
                    color: Appearance.barSubtext
                }
            }
        }

        /*
         * 逐小时预报
         */
        ColumnLayout {
            Layout.fillWidth: true
            visible: WeatherService.ready
                && WeatherService.hourlyForecast.length > 0

            spacing: Appearance.px(6)

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(6)

                PanelText {
                    Layout.fillWidth: true
                    text: I18n.tr("hourlyForecast")
                    color: Appearance.barLayer0Text
                    font.weight: Font.DemiBold
                }

                LegendItem {
                    visible: hourlyChart.mode === 0
                    markerColor: root.chartBrightColor
                    Layout.alignment: Qt.AlignVCenter
                    label: I18n.tr("temperature")
                }

                LegendItem {
                    visible: hourlyChart.mode === 0
                    Layout.alignment: Qt.AlignVCenter
                    markerColor: root.chartDimColor
                    label: I18n.tr("feelsLike")
                }

                LegendItem {
                    visible: hourlyChart.mode === 1
                    markerColor: root.chartBrightColor
                    Layout.alignment: Qt.AlignVCenter
                    label: I18n.tr("precipitation")
                }

                LegendItem {
                    visible: hourlyChart.mode === 1
                    markerColor: root.chartDimColor
                    Layout.alignment: Qt.AlignVCenter
                    label: I18n.tr("humidity")
                }

                ModeButton {
                    text: I18n.tr("temperature")
                    selected: hourlyChart.mode === 0
                    onClicked: hourlyChart.mode = 0
                    Layout.alignment: Qt.AlignVCenter
                }

                ModeButton {
                    text: I18n.tr("precipitation")
                    selected: hourlyChart.mode === 1
                    onClicked: hourlyChart.mode = 1
                    Layout.alignment: Qt.AlignVCenter
                }

                ModeButton {
                    text: I18n.tr("windSpeed")
                    selected: hourlyChart.mode === 2
                    onClicked: hourlyChart.mode = 2
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(198)

                radius: Appearance.smallRadius
                color: root.chartSurfaceColor
                border.width: 1
                border.color: Appearance.barOutline

                HourlyChart {
                    id: hourlyChart

                    anchors {
                        fill: parent
                        margins: Appearance.px(7)
                    }
                }
            }
        }

        /*
         * 七日预报
         */
        ColumnLayout {
            Layout.fillWidth: true
            visible: WeatherService.ready
                && WeatherService.dailyForecast.length > 0

            spacing: Appearance.px(6)

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(6)

                PanelText {
                    Layout.fillWidth: true
                    text: I18n.tr("dailyForecast")
                    color: Appearance.barLayer0Text
                    font.weight: Font.DemiBold
                }

                LegendItem {
                    visible: dailyChart.mode === 0
                    Layout.alignment: Qt.AlignVCenter
                    markerColor: root.chartBrightColor
                    label: I18n.tr("highTemperature")
                }

                LegendItem {
                    visible: dailyChart.mode === 0
                    Layout.alignment: Qt.AlignVCenter
                    markerColor: root.chartDimColor
                    label: I18n.tr("lowTemperature")
                }

                ModeButton {
                    text: I18n.tr("temperature")
                    Layout.alignment: Qt.AlignVCenter
                    selected: dailyChart.mode === 0
                    onClicked: dailyChart.mode = 0
                }

                ModeButton {
                    text: I18n.tr("precipitation")
                    Layout.alignment: Qt.AlignVCenter
                    selected: dailyChart.mode === 1
                    onClicked: dailyChart.mode = 1
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(210)

                radius: Appearance.smallRadius
                color: root.chartSurfaceColor
                border.width: 1
                border.color: Appearance.barOutline

                DailyChart {
                    id: dailyChart

                    anchors {
                        fill: parent
                        margins: Appearance.px(7)
                    }
                }
            }
        }

        PanelText {
            Layout.fillWidth: true
            visible: WeatherService.error !== ""

            text: WeatherService.error
            color: Appearance.barError
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Appearance.smallFontSize
        }
    }

    Connections {
        target: WeatherService
        ignoreUnknownSignals: true

        function onHourlyForecastChanged() {
            hourlyChart.repaint();
        }

        function onDailyForecastChanged() {
            dailyChart.repaint();
        }

        function onReadyChanged() {
            hourlyChart.repaint();
            dailyChart.repaint();
        }
    }
}
