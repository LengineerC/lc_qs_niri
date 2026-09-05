pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Widgets
import qs.common
import qs.common.widgets
import qs.services

ClippingRectangle {
    id: root

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }
    
    readonly property string timeText: {
        const total = FocusTimerService.remainingSeconds;
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        const minuteText = String(minutes).padStart(2, "0");
        const secondText = String(seconds).padStart(2, "0");
        return hours > 0
            ? String(hours).padStart(2, "0") + ":"
                + minuteText + ":" + secondText
            : minuteText + ":" + secondText;
    }

    function syncDurationFields(): void {
        if (hourInput.activeFocus
                || minuteInput.activeFocus
                || secondInput.activeFocus) {
            return;
        }

        const total = FocusTimerService.currentDurationSeconds;
        hourInput.text = String(Math.floor(total / 3600))
            .padStart(2, "0");
        minuteInput.text = String(Math.floor((total % 3600) / 60))
            .padStart(2, "0");
        secondInput.text = String(total % 60).padStart(2, "0");
    }

    function inputNumber(input): int {
        const value = Number.parseInt(input.text, 10);
        return Number.isFinite(value) ? value : 0;
    }

    function applyCustomDuration(): void {
        const hours = Math.max(0, Math.min(99,
            inputNumber(hourInput)));
        const minutes = Math.max(0, Math.min(59,
            inputNumber(minuteInput)));
        const seconds = Math.max(0, Math.min(59,
            inputNumber(secondInput)));
        const total = hours * 3600 + minutes * 60 + seconds;

        FocusTimerService.setDuration(Math.max(1, total));
        forceActiveFocus();
        syncDurationFields();
    }

    Layout.fillWidth: true
    implicitHeight: Appearance.px(175)
    radius: Appearance.px(24)
    color: Appearance.barLayer3
    border.width: 1
    border.color: Appearance.withAlpha(
        Appearance.barOutline, 0.58)
    clip: true

    Component.onCompleted: syncDurationFields()

    Connections {
        target: FocusTimerService

        function onCurrentDurationSecondsChanged() {
            root.syncDurationFields();
        }
    }

    Canvas {
        id: oceanCanvas

        anchors.fill: parent
        antialiasing: true

        // progress 从 1 降到 0，Behavior 让每秒一次的水位变化保持连续。
        property real waterLevel: FocusTimerService.progress
        property real phase: 0

        Behavior on waterLevel {
            NumberAnimation {
                duration: 720
                easing.type: Easing.InOutSine
            }
        }

        function waveSurfaceY(amplitude) {
            const fullSurface = height * 0.22;
            const emptySurface = height + amplitude * 1.25;
            return emptySurface
                + (fullSurface - emptySurface) * waterLevel;
        }

        function drawWave(context, surfaceY, amplitude,
                wavelength, phaseOffset, fillColor) {
            const step = Math.max(2, Appearance.px(3));

            context.beginPath();
            context.moveTo(0, height);
            context.lineTo(0, surfaceY);

            for (let x = 0; x <= width + step; x += step) {
                const primaryWave = Math.sin(
                    x / wavelength * Math.PI * 2
                        + phase + phaseOffset);
                const detailWave = Math.sin(
                    x / (wavelength * 0.53) * Math.PI * 2
                        - phase * 0.62 + phaseOffset * 1.7);
                const y = surfaceY
                    + primaryWave * amplitude
                    + detailWave * amplitude * 0.22;
                context.lineTo(x, y);
            }

            context.lineTo(width, height);
            context.closePath();
            context.fillStyle = fillColor;
            context.fill();
        }

        function drawBubbles(context, surfaceY) {
            if (waterLevel <= 0.04)
                return;

            const waterHeight = Math.max(1, height - surfaceY);
            for (let index = 0; index < 13; ++index) {
                const x = ((index * 53 + 17) % Math.max(1, width));
                const travel = waterHeight + Appearance.px(18);
                const y = height - ((index * 31
                    + phase * (8 + index % 4) * Appearance.px(1))
                    % travel);
                if (y < surfaceY + Appearance.px(8))
                    continue;

                const radius = Appearance.px(
                    index % 3 === 0 ? 1.5 : 0.9);
                context.strokeStyle = Appearance.withAlpha(
                    Appearance.barPrimaryContainerText,
                    0.08 + index % 4 * 0.015);
                context.lineWidth = Appearance.px(0.8);
                context.beginPath();
                context.arc(x, y, radius, 0, Math.PI * 2);
                context.stroke();
            }
        }

        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);

            const rearAmplitude = Appearance.px(5.5);
            const frontAmplitude = Appearance.px(4);
            const rearSurface = waveSurfaceY(rearAmplitude)
                - Appearance.px(3);
            const frontSurface = waveSurfaceY(frontAmplitude);

            // 水下的轻微纵向渐变，避免大面积纯色压住卡片内容。
            const depthGradient = context.createLinearGradient(
                0, frontSurface, 0, height);
            depthGradient.addColorStop(0,
                Appearance.withAlpha(Appearance.barPrimary, 0.09));
            depthGradient.addColorStop(1,
                Appearance.withAlpha(
                    Appearance.barPrimaryContainer, 0.22));
            context.fillStyle = depthGradient;
            context.fillRect(0, Math.max(0, frontSurface),
                width, Math.max(0, height - frontSurface));

            drawWave(
                context,
                rearSurface,
                rearAmplitude,
                Appearance.px(92),
                1.45,
                Appearance.withAlpha(Appearance.barTertiary, 0.1)
            );
            drawWave(
                context,
                frontSurface,
                frontAmplitude,
                Appearance.px(74),
                0,
                Appearance.withAlpha(Appearance.barPrimary, 0.13)
            );
            drawBubbles(context, frontSurface);
        }

        onWaterLevelChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Timer {
            interval: 40
            repeat: true
            running: FocusTimerService.running && oceanCanvas.visible
            onTriggered: {
                oceanCanvas.phase = (oceanCanvas.phase + 0.045)
                    % (Math.PI * 2);
                oceanCanvas.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(9)
        }
        spacing: Appearance.px(4)

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                id: resetButton

                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: Appearance.px(4)
                    leftMargin: Appearance.px(2)
                }
                width: Appearance.px(28)
                height: width
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: FocusTimerService.reset()

                AppText {
                    anchors.centerIn: parent
                    text: "󰑓"
                    color: resetButton.containsMouse
                        ? Appearance.barPrimary : Appearance.barLayer1Text
                    scale: resetButton.pressed ? 0.86 : 1
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
                        pixelSize: Appearance.px(15)
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                        }
                    }
                }

                StyledToolTip {
                    visible: resetButton.containsMouse
                    text: I18n.tr("reset")
                    delay: 500
                }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: Appearance.px(13)
                    rightMargin: Appearance.px(11)
                }
                width: Appearance.px(7)
                height: width
                radius: Appearance.fullRadius
                color: FocusTimerService.running
                    ? Appearance.barPrimary : Appearance.barOutline

                SequentialAnimation on opacity {
                    running: FocusTimerService.running
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.3
                        duration: 650
                    }
                    NumberAnimation {
                        to: 1
                        duration: 650
                    }
                }
            }

            Item {
                id: timerDial

                width: Appearance.px(96)
                height: width
                anchors.centerIn: parent

                Shape {
                    anchors.fill: parent

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Appearance.withAlpha(
                            Appearance.barOutline, 0.42)
                        strokeWidth: Appearance.px(5)
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: timerDial.width / 2
                            centerY: timerDial.height / 2
                            radiusX: Appearance.px(41)
                            radiusY: Appearance.px(41)
                            startAngle: -90
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Appearance.barPrimary
                        strokeWidth: Appearance.px(5)
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: timerDial.width / 2
                            centerY: timerDial.height / 2
                            radiusX: Appearance.px(41)
                            radiusY: Appearance.px(41)
                            startAngle: -90
                            sweepAngle: 360 * FocusTimerService.progress
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -Appearance.px(1)
                    spacing: -Appearance.px(1)

                    AppText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.timeText
                        color: Appearance.barLayer0Text
                        font {
                            family: Appearance.monospaceFontFamily
                            pixelSize: Appearance.px(
                                FocusTimerService.remainingSeconds >= 3600
                                    ? 15 : 19)
                            weight: Font.DemiBold
                        }
                    }

                    AppText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: FocusTimerService.mode === "custom"
                            ? I18n.tr("customTime") : "5 min"
                        color: Appearance.barSubtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.px(9)
                            weight: Font.Medium
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: FocusTimerService.toggle()

                    StyledToolTip {
                        visible: parent.containsMouse
                        text: FocusTimerService.running
                            ? I18n.tr("pause") : I18n.tr("start")
                        delay: 500
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.minimumHeight: Appearance.px(29)
            Layout.preferredHeight: Appearance.px(29)
            Layout.maximumHeight: Appearance.px(29)
            spacing: Appearance.px(3)

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.px(8)
                color: Appearance.barLayer1
                border.width: 1
                border.color: hourInput.activeFocus
                    ? Appearance.barPrimary
                    : Appearance.withAlpha(Appearance.barOutline, 0.4)

                AppTextInput {
                    id: hourInput

                    anchors.fill: parent
                    color: Appearance.barLayer0Text
                    selectionColor: Appearance.barPrimaryContainer
                    selectedTextColor: Appearance.barPrimaryContainerText
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    inputMethodHints: Qt.ImhDigitsOnly
                    maximumLength: 2
                    validator: IntValidator { bottom: 0; top: 99 }
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: Appearance.px(11)
                    }
                    Keys.onReturnPressed: root.applyCustomDuration()
                    Keys.onEnterPressed: root.applyCustomDuration()
                }
            }

            AppText {
                text: ":"
                color: Appearance.barSubtext
                font.family: Appearance.monospaceFontFamily
                font.pixelSize: Appearance.px(11)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.px(8)
                color: Appearance.barLayer1
                border.width: 1
                border.color: minuteInput.activeFocus
                    ? Appearance.barPrimary
                    : Appearance.withAlpha(Appearance.barOutline, 0.4)

                AppTextInput {
                    id: minuteInput

                    anchors.fill: parent
                    color: Appearance.barLayer0Text
                    selectionColor: Appearance.barPrimaryContainer
                    selectedTextColor: Appearance.barPrimaryContainerText
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    inputMethodHints: Qt.ImhDigitsOnly
                    maximumLength: 2
                    validator: IntValidator { bottom: 0; top: 59 }
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: Appearance.px(11)
                    }
                    Keys.onReturnPressed: root.applyCustomDuration()
                    Keys.onEnterPressed: root.applyCustomDuration()
                }
            }

            AppText {
                text: ":"
                color: Appearance.barSubtext
                font.family: Appearance.monospaceFontFamily
                font.pixelSize: Appearance.px(11)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.px(8)
                color: Appearance.barLayer1
                border.width: 1
                border.color: secondInput.activeFocus
                    ? Appearance.barPrimary
                    : Appearance.withAlpha(Appearance.barOutline, 0.4)

                AppTextInput {
                    id: secondInput

                    anchors.fill: parent
                    color: Appearance.barLayer0Text
                    selectionColor: Appearance.barPrimaryContainer
                    selectedTextColor: Appearance.barPrimaryContainerText
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    inputMethodHints: Qt.ImhDigitsOnly
                    maximumLength: 2
                    validator: IntValidator { bottom: 0; top: 59 }
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: Appearance.px(11)
                    }
                    Keys.onReturnPressed: root.applyCustomDuration()
                    Keys.onEnterPressed: root.applyCustomDuration()
                }
            }

            MouseArea {
                id: applyButton

                Layout.preferredWidth: Appearance.px(28)
                Layout.fillHeight: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyCustomDuration()

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.px(9)
                    color: applyButton.containsMouse
                        ? Appearance.barPrimaryContainer
                        : Appearance.withAlpha(Appearance.barPrimary, 0.1)

                    AppText {
                        anchors.centerIn: parent
                        text: "󰄬"
                        color: Appearance.barPrimary
                        font {
                            family: Appearance.iconFontFamily
                            weight: Font.Normal
                            pixelSize: Appearance.px(14)
                        }
                    }
                }

                StyledToolTip {
                    visible: applyButton.containsMouse
                    text: I18n.tr("apply")
                    delay: 500
                }
            }
        }

    }
}
