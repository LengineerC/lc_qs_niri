pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    implicitWidth: Appearance.px(850)
    implicitHeight: contentColumn.implicitHeight
        + Appearance.px(28)

    component PanelText: Text {
        color: Appearance.layer1Text

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
            ? Appearance.primaryContainer
            : area.containsMouse
                ? Appearance.layer1Active
                : Appearance.layer3

        border.width: 1
        border.color: selected
            ? Appearance.primary
            : Appearance.outline

        PanelText {
            id: label

            anchors.centerIn: parent
            text: button.text

            color: button.selected
                ? Appearance.primaryContainerText
                : Appearance.subtext

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
            color: Appearance.subtext
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
        color: Appearance.layer2
        border.width: 1
        border.color: Appearance.outline

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
                color: Appearance.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: metric.icon
                    color: Appearance.primaryContainerText

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
                    color: Appearance.subtext
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.smallFontSize
                }

                PanelText {
                    Layout.fillWidth: true
                    text: metric.value
                    color: Appearance.layer0Text
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
            Appearance.primary
        readonly property color secondaryLine:
            Theme.palette.m3tertiary

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
                    Appearance.outline, 0.36);
                context.fillStyle = Appearance.subtext;
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
                                ? Appearance.primary
                                : Appearance.subtext

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
                                ? Appearance.primary
                                : Appearance.subtext

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
            Appearance.primary
        readonly property color minimumColor:
            Theme.palette.m3tertiary

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
                    Appearance.outline, 0.36);
                context.fillStyle = Appearance.subtext;
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
                                ? Appearance.primary
                                : Appearance.subtext

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
                                ? Appearance.primary
                                : Appearance.subtext

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

        /*
         * 标题栏
         */
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            Text {
                text: WeatherService.currentIcon
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(22)
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: I18n.tr("weather")
                color: Appearance.layer0Text
                font {
                    pixelSize: Appearance.largeFontSize
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                implicitWidth: Appearance.px(30)
                implicitHeight: Appearance.px(30)
                radius: Appearance.fullRadius
                color: refreshArea.containsMouse
                    ? Appearance.layer1Active : "transparent"
                opacity: WeatherService.loading ? 0.55 : 1

                Text {
                    id: refreshIcon

                    anchors.centerIn: parent
                    text: "󰑐"
                    color: Appearance.subtext
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

            CloseButton {
                onClicked: root.closeRequested()
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.outline
            opacity: 0.55
        }


        /*
         * 当前天气
         */
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(190)

            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

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
                        color: Appearance.primaryContainer

                        Text {
                            anchors.centerIn: parent
                            text: WeatherService.currentIcon
                            color: Appearance.primaryContainerText

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
                            color: Appearance.layer0Text

                            font {
                                pixelSize: Appearance.px(31)
                                weight: Font.Medium
                            }
                        }

                        PanelText {
                            Layout.fillWidth: true

                            text: WeatherService.description(
                                WeatherService.current.weatherCode)

                            color: Appearance.layer0Text
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

                            color: Appearance.subtext
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
                    color: Appearance.outline
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
                    color: Appearance.primary

                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(28)
                    }
                }

                PanelText {
                    text: WeatherService.loading
                        ? I18n.tr("weatherLoading")
                        : I18n.tr("weatherUnavailable")
                    color: Appearance.subtext
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
                    color: Appearance.layer0Text
                    font.weight: Font.DemiBold
                }

                LegendItem {
                    visible: hourlyChart.mode === 0
                    markerColor: Appearance.primary
                    Layout.alignment: Qt.AlignVCenter
                    label: I18n.tr("temperature")
                }

                LegendItem {
                    visible: hourlyChart.mode === 0
                    Layout.alignment: Qt.AlignVCenter
                    markerColor: Theme.palette.m3tertiary
                    label: I18n.tr("feelsLike")
                }

                LegendItem {
                    visible: hourlyChart.mode === 1
                    markerColor: Appearance.primary
                    Layout.alignment: Qt.AlignVCenter
                    label: I18n.tr("precipitation")
                }

                LegendItem {
                    visible: hourlyChart.mode === 1
                    markerColor: Theme.palette.m3tertiary
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
                color: Appearance.layer3
                border.width: 1
                border.color: Appearance.outline

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
                    color: Appearance.layer0Text
                    font.weight: Font.DemiBold
                }

                LegendItem {
                    visible: dailyChart.mode === 0
                    Layout.alignment: Qt.AlignVCenter
                    markerColor: Appearance.primary
                    label: I18n.tr("highTemperature")
                }

                LegendItem {
                    visible: dailyChart.mode === 0
                    Layout.alignment: Qt.AlignVCenter
                    markerColor: Theme.palette.m3tertiary
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
                color: Appearance.layer3
                border.width: 1
                border.color: Appearance.outline

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
            color: Theme.palette.m3error
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