pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

MouseArea {
    id: root

    signal activated

    property bool showDate: true

    readonly property color digitColor: Appearance.primary
    readonly property color colonColor:
        Appearance.mix(Appearance.tertiary, Appearance.subtext, 0.35)
    readonly property int clockFontSize:
        Appearance.fontSize + Appearance.px(3)
    readonly property int digitWidth:
        Math.ceil(digitMeasure.implicitWidth) + Appearance.px(1)
    readonly property int digitHeight:
        Math.ceil(digitMeasure.implicitHeight) + Appearance.px(1)
    readonly property string timeText:
        I18n.locale.toString(now, ShellSettings.timeFormat)
    readonly property string dateText:
        I18n.locale.toString(now, ShellSettings.dateFormat)

    property date now: new Date()

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: timeRow.implicitWidth + Appearance.px(18)
    implicitHeight: Appearance.barHeight
    onClicked: activated()

    Text {
        id: digitMeasure

        visible: false
        text: "8"
        font {
            family: Appearance.fontFamily
            pixelSize: root.clockFontSize
            weight: Font.DemiBold
        }
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: root.containsMouse
            ? Appearance.layer1Hover : Appearance.layer1
        border.width: 1
        border.color: Appearance.outline
        scale: root.pressed ? 0.94 : 1

        Behavior on color {
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

                implicitWidth: isDigit
                    ? root.digitWidth : staticCharacter.implicitWidth
                implicitHeight: root.digitHeight

                AnimatedDigit {
                    visible: parent.isDigit
                    anchors.fill: parent
                    value: parent.character
                }

                Text {
                    id: staticCharacter

                    visible: !parent.isDigit
                    anchors.centerIn: parent
                    text: parent.character
                    color: text === ":"
                        ? root.colonColor : root.digitColor
                    font {
                        family: Appearance.fontFamily
                        pixelSize: root.clockFontSize
                        weight: text === ":" ? Font.Bold : Font.DemiBold
                    }
                }
            }
        }

        Text {
            visible: root.showDate
            Layout.leftMargin: Appearance.px(4)
            text: "|"
            color: Appearance.subtext
            verticalAlignment: Text.AlignVCenter
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.fontSize
            }
        }

        Text {
            visible: root.showDate
            text: root.dateText
            color: Appearance.layer1Text
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

        Text {
            width: parent.width
            height: parent.height
            y: digit.progress * parent.height
            visible: digit.outgoingValue !== ""
            text: digit.outgoingValue
            color: root.digitColor
            opacity: 1 - digit.progress * 0.35
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font {
                family: Appearance.fontFamily
                pixelSize: root.clockFontSize
                weight: Font.DemiBold
            }
        }

        Text {
            width: parent.width
            height: parent.height
            y: (digit.progress - 1) * parent.height
            text: digit.displayedValue
            color: root.digitColor
            opacity: 0.65 + digit.progress * 0.35
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font {
                family: Appearance.fontFamily
                pixelSize: root.clockFontSize
                weight: Font.DemiBold
            }
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
}
