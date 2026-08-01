pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.common
import qs.common.widgets

Item {
    id: root

    signal closeRequested

    property date currentDate: new Date()
    property date displayedDate: new Date(
        currentDate.getFullYear(), currentDate.getMonth(), 1)
    property date selectedDate: currentDate

    readonly property int displayedMonth: displayedDate.getMonth()
    readonly property int displayedYear: displayedDate.getFullYear()
    readonly property bool displayingCurrentMonth:
        displayedMonth === currentDate.getMonth()
        && displayedYear === currentDate.getFullYear()

    implicitWidth: Appearance.px(390)
    implicitHeight: contentColumn.implicitHeight + Appearance.px(28)

    function showPreviousMonth() {
        displayedDate = new Date(
            displayedYear, displayedMonth - 1, 1);
    }

    function showNextMonth() {
        displayedDate = new Date(
            displayedYear, displayedMonth + 1, 1);
    }

    function showToday() {
        currentDate = new Date();
        selectedDate = currentDate;
        displayedDate = new Date(
            currentDate.getFullYear(), currentDate.getMonth(), 1);
    }

    function sameDate(first, second) {
        return first.getFullYear() === second.getFullYear()
            && first.getMonth() === second.getMonth()
            && first.getDate() === second.getDate();
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component RoundButton: Rectangle {
        id: button

        required property string icon
        signal clicked

        implicitWidth: Appearance.px(28)
        implicitHeight: Appearance.px(28)
        radius: Appearance.fullRadius
        color: buttonMouse.containsMouse
            ? Appearance.layer1Active : "transparent"
        scale: buttonMouse.pressed ? 0.88 : 1

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: Appearance.layer1Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(15)
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation { duration: Appearance.fastDuration }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            showToday();
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentDate = new Date()
    }

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.y !== 0
                ? event.angleDelta.y : event.pixelDelta.y;
            if (delta > 0)
                root.showPreviousMonth();
            else if (delta < 0)
                root.showNextMonth();
            event.accepted = delta !== 0;
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
        spacing: Appearance.px(8)

        PopupHeader {
            icon: "󰃭"
            title: I18n.tr("calendar")
            subtitle: I18n.locale.toString(
                root.currentDate, "dddd, MMMM dd")
            dividerSpacing: Appearance.px(8)
            onCloseClicked: root.closeRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(74)
            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.px(3)

                PanelText {
                    text: I18n.locale.toString(
                        root.currentDate, "HH")
                    color: Appearance.layer0Text
                    font {
                        pixelSize: Appearance.px(34)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: ":"
                    color: Appearance.primary
                    font {
                        pixelSize: Appearance.px(32)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: I18n.locale.toString(
                        root.currentDate, "mm")
                    color: Appearance.layer0Text
                    font {
                        pixelSize: Appearance.px(34)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: ":"
                    color: Appearance.primary
                    font {
                        pixelSize: Appearance.px(32)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: I18n.locale.toString(
                        root.currentDate, "ss")
                    color: Appearance.tertiary
                    font {
                        pixelSize: Appearance.px(34)
                        weight: Font.Bold
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(5)

            RoundButton {
                icon: "󰅁"
                onClicked: root.showPreviousMonth()
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(32)
                radius: Appearance.fullRadius
                color: monthMouse.containsMouse
                    ? Appearance.layer1Hover : "transparent"

                PanelText {
                    anchors.centerIn: parent
                    text: I18n.locale.toString(
                        root.displayedDate, "MMMM yyyy")
                    color: root.displayingCurrentMonth
                        ? Appearance.primary : Appearance.layer0Text
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: monthMouse

                    anchors.fill: parent
                    enabled: !root.displayingCurrentMonth
                    hoverEnabled: true
                    cursorShape: enabled
                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.showToday()
                }

                Behavior on color {
                    ColorAnimation { duration: Appearance.fastDuration }
                }
            }

            RoundButton {
                icon: "󰅂"
                onClicked: root.showNextMonth()
            }
        }

        Controls.DayOfWeekRow {
            id: weekDays

            Layout.fillWidth: true
            locale: I18n.locale

            delegate: PanelText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: model.shortName
                color: model.day === Qt.Saturday
                    || model.day === Qt.Sunday
                    ? Appearance.tertiary : Appearance.subtext
                font {
                    pixelSize: Appearance.smallFontSize
                    weight: Font.DemiBold
                }
            }
        }

        Controls.MonthGrid {
            id: monthGrid

            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.px(222)
            month: root.displayedMonth
            year: root.displayedYear
            locale: I18n.locale
            spacing: Appearance.px(2)

            delegate: Rectangle {
                id: dayCell

                required property var model

                readonly property bool selected:
                    root.sameDate(model.date, root.selectedDate)
                readonly property bool weekend:
                    model.date.getDay() === 0
                    || model.date.getDay() === 6

                implicitWidth: Appearance.px(42)
                implicitHeight: Appearance.px(34)
                radius: Appearance.px(10)
                color: model.today
                    ? Appearance.primary
                    : selected
                        ? Appearance.secondaryContainer
                        : dayMouse.containsMouse
                            ? Appearance.layer1Hover : "transparent"

                PanelText {
                    anchors.centerIn: parent
                    text: dayCell.model.day
                    color: dayCell.model.today
                        ? Theme.palette.m3onPrimary
                        : dayCell.selected
                            ? Appearance.secondaryContainerText
                            : dayCell.weekend
                                ? Appearance.tertiary
                                : Appearance.layer1Text
                    opacity: dayCell.model.month === monthGrid.month ? 1 : 0.38
                    font {
                        pixelSize: Appearance.fontSize
                        weight: dayCell.model.today
                            || dayCell.selected ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    id: dayMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedDate = dayCell.model.date;
                        if (dayCell.model.month !== monthGrid.month) {
                            root.displayedDate = new Date(
                                dayCell.model.year,
                                dayCell.model.month, 1);
                        }
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: Appearance.fastDuration }
                }
            }
        }

        // 返回今天的按钮
        // Rectangle {
        //     Layout.alignment: Qt.AlignHCenter
        //     implicitWidth: todayLabel.implicitWidth + Appearance.px(24)
        //     implicitHeight: Appearance.px(30)
        //     radius: Appearance.fullRadius
        //     color: todayMouse.containsMouse
        //         ? Appearance.primaryContainer : Appearance.layer1
        //     border.width: 1
        //     border.color: Appearance.outline

        //     PanelText {
        //         id: todayLabel

        //         anchors.centerIn: parent
        //         text: I18n.tr("today")
        //         color: Appearance.primary
        //         font.weight: Font.DemiBold
        //     }

        //     MouseArea {
        //         id: todayMouse

        //         anchors.fill: parent
        //         hoverEnabled: true
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: root.showToday()
        //     }

        //     Behavior on color {
        //         ColorAnimation { duration: Appearance.fastDuration }
        //     }
        // }
    }
}
