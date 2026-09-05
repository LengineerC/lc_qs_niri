pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

MouseArea {
    id: root

    signal activated

    property bool showDate: true

    readonly property color firstDigitColor: ShellSettings.barFrostedGlass
        ? Appearance.barLayer0Text : Appearance.primary
    readonly property color secondDigitColor: ShellSettings.barFrostedGlass
        ? Appearance.barSubtext : Appearance.tertiary
    readonly property color colonColor:
        Appearance.withAlpha(Appearance.barSubtext, 0.45)
    readonly property int clockFontSize:
        Appearance.fontSize + Appearance.px(3)
    property real digitWeight: 2.5 * Appearance.scale

    readonly property int digitWidth: Appearance.px(13)
    readonly property int digitHeight: Appearance.px(17)
    readonly property int colonWidth: Appearance.px(7)
    readonly property string timeText:
        I18n.locale.toString(now, ShellSettings.timeFormat)
    readonly property string dateText:
        I18n.locale.toString(now, ShellSettings.dateFormat)

    property date now: new Date()

    function digitOrdinalAt(characterIndex) {
        let ordinal = 0;
        for (let index = 0; index < characterIndex; ++index) {
            if (/[0-9]/.test(timeText.charAt(index)))
                ++ordinal;
        }
        return ordinal;
    }

    function digitColorAt(characterIndex) {
        return digitOrdinalAt(characterIndex) % 2 === 0
            ? firstDigitColor : secondDigitColor;
    }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: timeRow.implicitWidth + Appearance.px(18)
    implicitHeight: Appearance.barHeight
    onClicked: activated()

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: root.containsMouse
            ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: 1
        border.color: Appearance.barOutline
        scale: root.pressed ? 0.94 : 1

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: timeRow

        anchors.centerIn: parent
        spacing: Appearance.px(1)

        Repeater {
            model: root.timeText.length

            delegate: Item {
                required property int index

                readonly property string character:
                    root.timeText.charAt(index)
                readonly property bool isDigit: /[0-9]/.test(character)
                readonly property bool isColon: character === ":"

                implicitWidth: isDigit
                    ? root.digitWidth
                    : isColon ? root.colonWidth
                    : staticCharacter.implicitWidth
                implicitHeight: root.digitHeight

                AnimatedDigit {
                    visible: parent.isDigit
                    anchors.fill: parent
                    value: parent.character
                    fillColor: root.digitColorAt(parent.index)
                }

                ClockColonImage {
                    visible: parent.isColon
                    anchors.fill: parent
                    fillColor: root.colonColor
                }

                AppText {
                    id: staticCharacter

                    visible: !parent.isDigit && !parent.isColon
                    anchors.centerIn: parent
                    text: parent.character
                    color: root.firstDigitColor
                    font {
                        family: Appearance.fontFamily
                        pixelSize: root.clockFontSize
                        weight: Font.ExtraBold
                    }
                }
            }
        }

        AppText {
            visible: root.showDate
            Layout.leftMargin: Appearance.px(4)
            Layout.rightMargin: Appearance.px(4)
            text: "|"
            color: Appearance.barSubtext
            verticalAlignment: Text.AlignVCenter
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.fontSize
            }
        }

        AppText {
            visible: root.showDate
            text: root.dateText
            color: Appearance.barLayer1Text
            verticalAlignment: Text.AlignVCenter
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.fontSize
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    component AnimatedDigit: Item {
        id: digit

        required property string value
        required property color fillColor
        property string displayedValue: ""
        property string outgoingValue: ""
        property real progress: 1
        property bool initialized: false

        implicitWidth: root.digitWidth
        implicitHeight: root.digitHeight
        clip: true

        function updateValue() {
            if (!initialized)
                return;
            if (value === displayedValue)
                return;

            slideAnimation.stop();
            outgoingValue = displayedValue;
            displayedValue = value;
            progress = 0;
            slideAnimation.start();
        }

        onValueChanged: updateValue()

        Component.onCompleted: {
            displayedValue = value;
            initialized = true;
        }

        ClockDigitImage {
            width: parent.width
            height: parent.height
            y: digit.progress * parent.height
            visible: digit.outgoingValue !== ""
            value: digit.outgoingValue
            fillColor: digit.fillColor
            opacity: 1 - digit.progress * 0.35
        }

        ClockDigitImage {
            width: parent.width
            height: parent.height
            y: (digit.progress - 1) * parent.height
            value: digit.displayedValue
            fillColor: digit.fillColor
            opacity: 0.65 + digit.progress * 0.35
        }

        NumberAnimation {
            id: slideAnimation

            target: digit
            property: "progress"
            from: 0
            to: 1
            duration: Math.max(180,
                Math.round(ShellSettings.animationDuration * 0.8))
            easing.type: Easing.OutCubic
            onFinished: digit.outgoingValue = ""
        }
    }

    component ClockDigitImage: Canvas {
        id: digitCanvas

        required property string value
        required property color fillColor

        antialiasing: true
        renderTarget: Canvas.Image

        function repaint() {
            requestPaint();
        }

        onValueChanged: repaint()
        onFillColorChanged: repaint()
        onWidthChanged: repaint()
        onHeightChanged: repaint()
        Component.onCompleted: repaint()

        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);
            const number = String(value);
            if (!/[0-9]/.test(number))
                return;

            const strokeWidth = Math.max(1, root.digitWeight);
            const margin = strokeWidth * 0.58;
            const innerWidth = Math.max(1, width - margin * 2);
            const innerHeight = Math.max(1, height - margin * 2);

            function point(x, y) {
                return [
                    margin + x * innerWidth,
                    margin + y * innerHeight
                ];
            }

            function moveTo(x, y) {
                const target = point(x, y);
                context.moveTo(target[0], target[1]);
            }

            function lineTo(x, y) {
                const target = point(x, y);
                context.lineTo(target[0], target[1]);
            }

            function curveTo(c1x, c1y, c2x, c2y, x, y) {
                const control1 = point(c1x, c1y);
                const control2 = point(c2x, c2y);
                const target = point(x, y);
                context.bezierCurveTo(
                    control1[0], control1[1],
                    control2[0], control2[1],
                    target[0], target[1]);
            }

            context.strokeStyle = fillColor;
            context.lineWidth = strokeWidth;
            context.lineCap = "round";
            context.lineJoin = "round";

            function beginAt(x, y) {
                context.beginPath();
                moveTo(x, y);
            }

            function finish() {
                context.stroke();
            }

            switch (number) {
            case "0":
                beginAt(0.58, 0.02);
                curveTo(0.28, -0.01, 0.08, 0.20, 0.06, 0.50);
                curveTo(0.04, 0.80, 0.21, 1.01, 0.49, 0.98);
                curveTo(0.77, 0.95, 0.92, 0.72, 0.94, 0.43);
                curveTo(0.96, 0.16, 0.84, 0.04, 0.58, 0.02);
                finish();
                break;
            case "1":
                beginAt(0.16, 0.24);
                lineTo(0.54, 0.03);
                lineTo(0.43, 0.97);
                finish();
                break;
            case "2":
                beginAt(0.14, 0.23);
                curveTo(0.29, 0.01, 0.69, -0.04, 0.84, 0.15);
                curveTo(1.00, 0.36, 0.73, 0.52, 0.53, 0.64);
                lineTo(0.10, 0.96);
                lineTo(0.78, 0.96);
                finish();
                break;
            case "3":
                beginAt(0.18, 0.13);
                curveTo(0.43, -0.03, 0.79, 0.01, 0.84, 0.23);
                curveTo(0.88, 0.40, 0.72, 0.49, 0.53, 0.52);
                curveTo(0.76, 0.51, 0.88, 0.64, 0.83, 0.79);
                curveTo(0.77, 1.00, 0.39, 1.04, 0.12, 0.88);
                finish();
                break;
            case "4":
                beginAt(0.76, 0.97);
                lineTo(0.83, 0.03);
                moveTo(0.78, 0.11);
                lineTo(0.10, 0.65);
                lineTo(0.87, 0.65);
                finish();
                break;
            case "5":
                beginAt(0.84, 0.06);
                lineTo(0.27, 0.06);
                lineTo(0.18, 0.48);
                curveTo(0.41, 0.39, 0.75, 0.42, 0.82, 0.63);
                curveTo(0.90, 0.88, 0.55, 1.06, 0.14, 0.88);
                finish();
                break;
            case "6":
                beginAt(0.79, 0.08);
                curveTo(0.42, 0.14, 0.16, 0.39, 0.12, 0.68);
                curveTo(0.08, 0.96, 0.43, 1.05, 0.69, 0.91);
                curveTo(0.95, 0.77, 0.84, 0.49, 0.59, 0.46);
                curveTo(0.42, 0.43, 0.25, 0.49, 0.15, 0.62);
                finish();
                break;
            case "7":
                beginAt(0.13, 0.07);
                lineTo(0.88, 0.07);
                lineTo(0.34, 0.97);
                finish();
                break;
            case "8":
                beginAt(0.55, 0.02);
                curveTo(0.28, 0.01, 0.15, 0.16, 0.20, 0.32);
                curveTo(0.25, 0.48, 0.68, 0.51, 0.76, 0.31);
                curveTo(0.84, 0.11, 0.70, 0.02, 0.55, 0.02);
                moveTo(0.48, 0.50);
                curveTo(0.20, 0.52, 0.08, 0.72, 0.17, 0.87);
                curveTo(0.28, 1.05, 0.70, 1.02, 0.80, 0.81);
                curveTo(0.90, 0.60, 0.69, 0.50, 0.48, 0.50);
                finish();
                break;
            case "9":
                beginAt(0.78, 0.48);
                curveTo(0.63, 0.60, 0.26, 0.57, 0.18, 0.34);
                curveTo(0.09, 0.09, 0.36, -0.04, 0.62, 0.04);
                curveTo(0.84, 0.11, 0.83, 0.33, 0.78, 0.48);
                curveTo(0.71, 0.73, 0.55, 0.90, 0.29, 0.98);
                finish();
                break;
            }
        }
    }

    component ClockColonImage: Canvas {
        id: colonCanvas

        required property color fillColor

        antialiasing: true
        renderTarget: Canvas.Image

        function repaint() {
            requestPaint();
        }

        onFillColorChanged: repaint()
        onWidthChanged: repaint()
        onHeightChanged: repaint()
        Component.onCompleted: repaint()

        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);
            context.fillStyle = fillColor;

            const radius = Math.max(1.5, width * 0.3);
            const centerX = width / 2;
            for (const centerY of [height * 0.36, height * 0.67]) {
                context.beginPath();
                context.arc(centerX, centerY, radius,
                    0, Math.PI * 2);
                context.fill();
            }
        }
    }
}
