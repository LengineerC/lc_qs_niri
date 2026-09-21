pragma ComponentBehavior: Bound

import QtQuick
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
    property date pendingDisplayedDate: displayedDate
    property int monthTransitionDirection: 1
    readonly property bool monthTransitionRunning: monthTransition.running

    readonly property int displayedMonth: displayedDate.getMonth()
    readonly property int displayedYear: displayedDate.getFullYear()
    readonly property bool displayingCurrentMonth:
        displayedMonth === currentDate.getMonth()
        && displayedYear === currentDate.getFullYear()
    readonly property int firstDayOfWeek:
        ShellSettings.calendarWeekStart >= 0
            ? ShellSettings.calendarWeekStart
            : Number(I18n.locale.firstDayOfWeek)
    readonly property var weekDayOrder: {
        const result = [];
        for (let offset = 0; offset < 7; ++offset)
            result.push((firstDayOfWeek + offset) % 7);
        return result;
    }
    readonly property date firstGridDate: {
        const firstOfMonth = new Date(
            displayedYear, displayedMonth, 1);
        const leadingDays = (firstOfMonth.getDay()
            - firstDayOfWeek + 7) % 7;
        return new Date(displayedYear, displayedMonth,
            1 - leadingDays);
    }

    implicitWidth: Appearance.px(390)
    implicitHeight: contentColumn.implicitHeight + Appearance.px(28)

    function showPreviousMonth() {
        showMonth(new Date(displayedYear, displayedMonth - 1, 1));
    }

    function showNextMonth() {
        showMonth(new Date(displayedYear, displayedMonth + 1, 1));
    }

    function showMonth(date, animated = true) {
        const target = new Date(date.getFullYear(), date.getMonth(), 1);
        const currentKey = displayedYear * 12 + displayedMonth;
        const targetKey = target.getFullYear() * 12 + target.getMonth();
        if (targetKey === currentKey || monthTransition.running)
            return;
        if (!animated) {
            displayedDate = target;
            return;
        }
        pendingDisplayedDate = target;
        monthTransitionDirection = targetKey > currentKey ? 1 : -1;
        monthTransition.start();
    }

    function showToday(animated = true) {
        currentDate = new Date();
        selectedDate = currentDate;
        const todayMonth = new Date(
            currentDate.getFullYear(), currentDate.getMonth(), 1);
        if (animated)
            showMonth(todayMonth);
        else
            displayedDate = todayMonth;
    }

    function sameDate(first, second) {
        return first.getFullYear() === second.getFullYear()
            && first.getMonth() === second.getMonth()
            && first.getDate() === second.getDate();
    }

    function dateForCell(index) {
        return new Date(
            firstGridDate.getFullYear(),
            firstGridDate.getMonth(),
            firstGridDate.getDate() + index);
    }

    function shortWeekDayName(day) {
        // 2024-01-07 was a Sunday; JS weekdays use Sunday = 0.
        return I18n.locale.toString(
            new Date(2024, 0, 7 + day), "ddd");
    }

    component PanelText: AppText {
        color: Appearance.barLayer1Text
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
            ? Appearance.barLayer1Active
            : Appearance.withAlpha(Appearance.barLayer1Active, 0)
        scale: buttonMouse.pressed ? 0.88 : 1

        AppText {
            anchors.centerIn: parent
            text: button.icon
            color: Appearance.barLayer1Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
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
        monthTransition.stop();
        monthTitleTranslate.x = 0;
        monthTitle.opacity = 1;
        dateGridTranslate.x = 0;
        dateGrid.opacity = 1;
        if (visible)
            showToday(false);
    }

    SequentialAnimation {
        id: monthTransition

        ParallelAnimation {
            NumberAnimation {
                target: monthTitleTranslate
                property: "x"
                to: -root.monthTransitionDirection * Appearance.px(24)
                duration: Appearance.fastDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: monthTitle
                property: "opacity"
                to: 0
                duration: Appearance.fastDuration
            }
            NumberAnimation {
                target: dateGridTranslate
                property: "x"
                to: -root.monthTransitionDirection * Appearance.px(34)
                duration: Appearance.fastDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: dateGrid
                property: "opacity"
                to: 0
                duration: Appearance.fastDuration
            }
        }
        ScriptAction {
            script: {
                root.displayedDate = root.pendingDisplayedDate;
                monthTitleTranslate.x = root.monthTransitionDirection
                    * Appearance.px(24);
                dateGridTranslate.x = root.monthTransitionDirection
                    * Appearance.px(34);
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: monthTitleTranslate
                property: "x"
                to: 0
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: monthTitle
                property: "opacity"
                to: 1
                duration: Appearance.fastDuration
            }
            NumberAnimation {
                target: dateGridTranslate
                property: "x"
                to: 0
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: dateGrid
                property: "opacity"
                to: 1
                duration: Appearance.fastDuration
            }
        }
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
            margins: Appearance.panelPadding
        }
        spacing: Appearance.spacingSmall

        PopupHeader {
            useBarPalette: true
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
            color: Appearance.barLayer3
            border.width: 1
            border.color: Appearance.barOutline

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.px(3)

                PanelText {
                    text: I18n.locale.toString(
                        root.currentDate, "HH")
                    color: Appearance.barLayer0Text
                    font {
                        pixelSize: Appearance.px(34)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: ":"
                    color: Appearance.barPrimary
                    font {
                        pixelSize: Appearance.px(32)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: I18n.locale.toString(
                        root.currentDate, "mm")
                    color: Appearance.barLayer0Text
                    font {
                        pixelSize: Appearance.px(34)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: ":"
                    color: Appearance.barPrimary
                    font {
                        pixelSize: Appearance.px(32)
                        weight: Font.Bold
                    }
                }

                PanelText {
                    text: I18n.locale.toString(
                        root.currentDate, "ss")
                    color: Appearance.barTertiary
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
                    ? Appearance.barLayer1Hover
                    : Appearance.withAlpha(Appearance.barLayer1Hover, 0)

                PanelText {
                    id: monthTitle

                    anchors.centerIn: parent
                    text: I18n.locale.toString(
                        root.displayedDate, "MMMM yyyy")
                    color: root.displayingCurrentMonth
                        ? Appearance.barPrimary : Appearance.barLayer0Text
                    font.weight: Font.DemiBold
                    transform: Translate { id: monthTitleTranslate }
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

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: Appearance.px(2)
            rowSpacing: 0
            uniformCellWidths: true

            Repeater {
                model: root.weekDayOrder

                delegate: PanelText {
                    required property int modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: Appearance.px(22)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.shortWeekDayName(modelData)
                    color: modelData === 0 || modelData === 6
                        ? Appearance.barTertiary : Appearance.barSubtext
                    font {
                        pixelSize: Appearance.smallFontSize
                        weight: Font.DemiBold
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.px(222)
            clip: true

            GridLayout {
                id: dateGrid

                anchors.fill: parent
                columns: 7
                columnSpacing: Appearance.px(2)
                rowSpacing: Appearance.px(2)
                uniformCellWidths: true
                uniformCellHeights: true
                transform: Translate { id: dateGridTranslate }

                Repeater {
                    model: 42

                delegate: Rectangle {
                    id: dayCell

                    required property int index
                    readonly property date cellDate:
                        root.dateForCell(index)
                    readonly property bool selected:
                        root.sameDate(cellDate, root.selectedDate)
                    readonly property bool today:
                        root.sameDate(cellDate, root.currentDate)
                    readonly property bool inDisplayedMonth:
                        cellDate.getMonth() === root.displayedMonth
                        && cellDate.getFullYear() === root.displayedYear
                    readonly property bool weekend:
                        cellDate.getDay() === 0
                        || cellDate.getDay() === 6

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: Appearance.px(42)
                    implicitHeight: Appearance.px(34)
                    radius: Appearance.controlRadius
                    color: today
                        ? Appearance.barPrimary
                        : selected
                            ? Appearance.barSecondaryContainer
                            : dayMouse.containsMouse
                                ? Appearance.barLayer1Hover
                                : Appearance.withAlpha(
                                    Appearance.barLayer1Hover, 0)

                    PanelText {
                        anchors.centerIn: parent
                        text: dayCell.cellDate.getDate()
                        color: dayCell.today
                            ? Appearance.barOnPrimary
                            : dayCell.selected
                                ? Appearance.barSecondaryContainerText
                                : dayCell.weekend
                                    ? Appearance.barTertiary
                                    : Appearance.barLayer1Text
                        opacity: dayCell.inDisplayedMonth ? 1 : 0.38
                        font {
                            pixelSize: Appearance.fontSize
                            weight: dayCell.today || dayCell.selected
                                ? Font.DemiBold : Font.Normal
                        }
                    }

                    MouseArea {
                        id: dayMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedDate = dayCell.cellDate;
                            if (!dayCell.inDisplayedMonth)
                                root.showMonth(dayCell.cellDate);
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.fastDuration
                        }
                    }
                }
                }
            }
        }

        // 返回今天的按钮
        // Rectangle {
        //     Layout.alignment: Qt.AlignHCenter
        //     implicitWidth: todayLabel.implicitWidth + Appearance.px(24)
        //     implicitHeight: Appearance.compactControlHeight
        //     radius: Appearance.fullRadius
        //     color: todayMouse.containsMouse
        //         ? Appearance.barPrimaryContainer : Appearance.barLayer1
        //     border.width: 1
        //     border.color: Appearance.barOutline

        //     PanelText {
        //         id: todayLabel

        //         anchors.centerIn: parent
        //         text: I18n.tr("today")
        //         color: Appearance.barPrimary
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
