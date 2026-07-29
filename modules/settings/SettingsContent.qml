pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.common

// Content pane for the Niri-managed settings window.
Item {
    id: root

    signal closeRequested

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component SectionTitle: RowLayout {
        required property string icon
        required property string title

        Layout.fillWidth: true
        Layout.topMargin: Appearance.px(4)
        spacing: Appearance.px(8)

        Text {
            text: parent.icon
            color: Appearance.primary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(17)
            }
        }

        PanelText {
            text: parent.title
            color: Appearance.layer0Text
            font {
                pixelSize: Appearance.fontSize + Appearance.px(1)
                weight: Font.DemiBold
            }
        }
    }

    component SettingCard: Rectangle {
        default property alias content: cardLayout.children
        property real contentSpacing: Appearance.px(10)

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + Appearance.px(20)
        radius: Appearance.smallRadius
        color: Appearance.layer3
        border.width: 1
        border.color: Appearance.outline

        ColumnLayout {
            id: cardLayout
            anchors {
                fill: parent
                margins: Appearance.px(10)
            }
            spacing: parent.contentSpacing
        }
    }

    component SettingSwitch: Item {
        id: control

        required property bool checked
        signal toggled(bool checked)

        implicitWidth: Appearance.px(43)
        implicitHeight: Appearance.px(25)

        Rectangle {
            anchors.fill: parent
            radius: Appearance.fullRadius
            color: control.checked
                ? Appearance.primary : Appearance.layer1Active
            border.width: control.checked ? 0 : 1
            border.color: Appearance.subtext

            Rectangle {
                width: control.checked
                    ? Appearance.px(19) : Appearance.px(15)
                height: width
                radius: Appearance.fullRadius
                anchors.verticalCenter: parent.verticalCenter
                x: control.checked
                    ? parent.width - width - Appearance.px(3)
                    : Appearance.px(5)
                color: control.checked
                    ? Theme.palette.m3onPrimary : Appearance.subtext

                Behavior on x {
                    NumberAnimation {
                        duration: Appearance.fastDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.fastDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: control.toggled(!control.checked)
        }
    }

    component ValueSlider: Controls.Slider {
        id: slider

        Layout.fillWidth: true
        implicitHeight: Appearance.px(28)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2
                - height / 2
            width: slider.availableWidth
            height: Appearance.px(5)
            radius: Appearance.fullRadius
            color: Appearance.layer1Active

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: Appearance.primary
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition
                * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2
                - height / 2
            implicitWidth: Appearance.px(slider.pressed ? 12 : 16)
            implicitHeight: Appearance.px(22)
            radius: Appearance.fullRadius
            color: Appearance.primary

            Behavior on implicitWidth {
                NumberAnimation { duration: Appearance.fastDuration }
            }
        }
    }

    component SliderRow: RowLayout {
        id: row

        required property string label
        required property real currentValue
        property real from: 0
        property real to: 1
        property real stepSize: 0.01
        property string suffix: ""
        property int decimals: 2
        signal moved(real value)

        Layout.fillWidth: true
        spacing: Appearance.px(10)

        PanelText {
            Layout.preferredWidth: Appearance.px(118)
            text: row.label
            color: Appearance.layer1Text
        }

        ValueSlider {
            from: row.from
            to: row.to
            stepSize: row.stepSize
            value: row.currentValue
            onMoved: row.moved(value)
        }

        Rectangle {
            Layout.preferredWidth: Appearance.px(72)
            implicitHeight: Appearance.px(28)
            radius: Appearance.px(8)
            color: Appearance.layer1

            PanelText {
                anchors.centerIn: parent
                text: Number(row.currentValue).toFixed(row.decimals)
                    + row.suffix
                color: Appearance.subtext
                font.pixelSize: Appearance.smallFontSize
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        RowLayout {
            id: titleRow
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Appearance.px(18)
            }
            height: Appearance.px(34)
            spacing: Appearance.px(9)

            Text {
                text: "󰒓"
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(20)
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: "快速设置"
                color: Appearance.layer0Text
                font {
                    pixelSize: Appearance.largeFontSize
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                implicitWidth: Appearance.px(28)
                implicitHeight: Appearance.px(28)
                radius: Appearance.fullRadius
                color: closeArea.containsMouse
                    ? Appearance.layer1Active : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: Appearance.subtext
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(15)
                    }
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            anchors {
                top: titleRow.bottom
                left: parent.left
                right: parent.right
                leftMargin: Appearance.px(18)
                rightMargin: Appearance.px(18)
                topMargin: Appearance.px(4)
            }
            height: 1
            color: Appearance.outline
        }

        Flickable {
            id: flickable
            anchors {
                top: titleRow.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Appearance.px(10)
                leftMargin: Appearance.px(18)
                rightMargin: Appearance.px(10)
                bottomMargin: Appearance.px(14)
            }
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: settingsColumn
                width: flickable.width - Appearance.px(10)
                spacing: Appearance.px(9)

                SectionTitle {
                    icon: "󰔎"
                    title: "外观"
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(8)

                        PanelText {
                            Layout.fillWidth: true
                            text: "颜色模式"
                            color: Appearance.layer0Text
                        }

                        Repeater {
                            model: [
                                { label: "󰖔  亮色", mode: "light" },
                                { label: "󰖙  暗色", mode: "dark" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: Appearance.px(88)
                                implicitHeight: Appearance.px(32)
                                radius: Appearance.px(9)
                                color: Theme.mode === modelData.mode
                                    ? Appearance.primaryContainer
                                    : modeArea.containsMouse
                                        ? Appearance.layer1Active
                                        : Appearance.layer1
                                border.width: Theme.mode === modelData.mode ? 1 : 0
                                border.color: Appearance.primary

                                PanelText {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Theme.mode === modelData.mode
                                        ? Appearance.primaryContainerText
                                        : Appearance.layer1Text
                                    font.pixelSize: Appearance.smallFontSize
                                }

                                MouseArea {
                                    id: modeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Theme.setMode(parent.modelData.mode)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: "显示活动窗口图标"
                                color: Appearance.layer0Text
                            }
                            PanelText {
                                text: "App ID 和标题仍会保留"
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.showActiveWindowIcon
                            onToggled: checked => {
                                ShellSettings.showActiveWindowIcon = checked;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: "显示空工作区"
                                color: Appearance.layer0Text
                            }
                            PanelText {
                                text: "当前活动工作区始终保留"
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.showEmptyWorkspaces
                            onToggled: checked => {
                                ShellSettings.showEmptyWorkspaces = checked;
                            }
                        }
                    }
                }

                SectionTitle {
                    icon: "󰔛"
                    title: "动画"
                }

                SettingCard {
                    SliderRow {
                        label: "动画时长"
                        currentValue: ShellSettings.animationDuration
                        from: 100
                        to: 1200
                        stepSize: 10
                        decimals: 0
                        suffix: " ms"
                        onMoved: value => {
                            ShellSettings.animationDuration = Math.round(value);
                        }
                    }

                    PanelText {
                        text: "弹窗贝塞尔曲线  cubic-bezier(x₁, y₁, x₂, y₂)"
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    SliderRow {
                        label: "X₁"
                        currentValue: ShellSettings.popupBezierX1
                        onMoved: value => ShellSettings.popupBezierX1 = value
                    }
                    SliderRow {
                        label: "Y₁"
                        currentValue: ShellSettings.popupBezierY1
                        from: -0.5
                        to: 2
                        onMoved: value => ShellSettings.popupBezierY1 = value
                    }
                    SliderRow {
                        label: "X₂"
                        currentValue: ShellSettings.popupBezierX2
                        onMoved: value => ShellSettings.popupBezierX2 = value
                    }
                    SliderRow {
                        label: "Y₂"
                        currentValue: ShellSettings.popupBezierY2
                        from: -0.5
                        to: 2
                        onMoved: value => ShellSettings.popupBezierY2 = value
                    }
                }

                SectionTitle {
                    icon: "󰛖"
                    title: "Bar 字体与尺寸"
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        PanelText {
                            Layout.preferredWidth: Appearance.px(118)
                            text: "字体"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Appearance.px(34)
                            radius: Appearance.px(9)
                            color: Appearance.layer1
                            border.width: fontInput.activeFocus ? 1 : 0
                            border.color: Appearance.primary

                            TextInput {
                                id: fontInput
                                anchors {
                                    fill: parent
                                    leftMargin: Appearance.px(10)
                                    rightMargin: Appearance.px(10)
                                }
                                verticalAlignment: TextInput.AlignVCenter
                                color: Appearance.layer0Text
                                selectionColor: Appearance.primaryContainer
                                selectedTextColor: Appearance.primaryContainerText
                                text: ShellSettings.barFontFamily
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                }
                                onEditingFinished: {
                                    if (text.trim())
                                        ShellSettings.barFontFamily = text.trim();
                                    else
                                        text = ShellSettings.barFontFamily;
                                }
                            }
                        }
                    }

                    SliderRow {
                        label: "字号"
                        currentValue: ShellSettings.barFontSize
                        from: 9
                        to: 24
                        stepSize: 1
                        decimals: 0
                        suffix: " px"
                        onMoved: value => {
                            ShellSettings.barFontSize = Math.round(value);
                        }
                    }

                    SliderRow {
                        label: "整体缩放"
                        currentValue: ShellSettings.scale
                        from: 0.75
                        to: 1.5
                        stepSize: 0.05
                        decimals: 2
                        suffix: "×"
                        onMoved: value => ShellSettings.scale = value
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: Appearance.px(4)
                    implicitWidth: resetText.implicitWidth + Appearance.px(24)
                    implicitHeight: Appearance.px(34)
                    radius: Appearance.px(10)
                    color: resetArea.containsMouse
                        ? Appearance.layer1Active : Appearance.layer1
                    border.width: 1
                    border.color: Appearance.outline

                    PanelText {
                        id: resetText
                        anchors.centerIn: parent
                        text: "󰑓  恢复默认"
                        color: Appearance.layer1Text
                        font.pixelSize: Appearance.smallFontSize
                    }

                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellSettings.resetDefaults()
                    }
                }
            }
        }
    }
}
