pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    readonly property var transformOptions: [
        { value: "normal", label: I18n.tr("orientationNormal") },
        { value: "90", label: I18n.tr("orientation90") },
        { value: "180", label: I18n.tr("orientation180") },
        { value: "270", label: I18n.tr("orientation270") },
        { value: "flipped", label: I18n.tr("orientationFlipped") },
        { value: "flipped-90", label: I18n.tr("orientationFlipped90") },
        { value: "flipped-180",
            label: I18n.tr("orientationFlipped180") },
        { value: "flipped-270",
            label: I18n.tr("orientationFlipped270") }
    ]
    readonly property var bpcOptions: [6, 8, 10, 12, 14, 16]
        .map(value => ({
            value: value,
            label: value + " " + I18n.tr("bitsPerChannel")
        }))

    function indexForValue(model, value) {
        if (!model)
            return -1;
        for (let index = 0; index < model.length; index++) {
            if (String(model[index].value) === String(value))
                return index;
        }
        return -1;
    }

    function scaleOptions(currentScale) {
        const values = [1, 1.25, 1.5, 1.75, 2, 2.5, 3];
        const scale = Number(currentScale) || 1;
        if (!values.some(value => Math.abs(value - scale) < 0.001))
            values.push(scale);
        values.sort((first, second) => first - second);
        return values.map(value => ({
            value: value,
            label: Number(value).toFixed(
                Number.isInteger(value) ? 0 : 2) + "×"
        }));
    }

    onVisibleChanged: {
        if (visible) {
            OutputService.refresh();
            BrightnessService.refresh();
        }
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component SettingSwitch: Item {
        id: control

        required property bool checked
        signal toggled(bool checked)

        implicitWidth: Appearance.px(43)
        implicitHeight: Appearance.px(25)
        opacity: enabled ? 1 : 0.4

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
                    NumberAnimation { duration: Appearance.fastDuration }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: control.enabled
            cursorShape: enabled
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: control.toggled(!control.checked)
        }
    }

    component ActionButton: Rectangle {
        id: button

        required property string icon
        required property string label
        property bool primary: false
        signal clicked

        implicitWidth: buttonRow.implicitWidth + Appearance.px(20)
        implicitHeight: Appearance.px(34)
        radius: Appearance.px(10)
        color: primary
            ? Appearance.primaryContainer
            : buttonArea.containsMouse
                ? Appearance.layer1Active : Appearance.layer1
        opacity: enabled ? 1 : 0.4
        scale: buttonArea.pressed ? 0.96 : 1

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: Appearance.px(6)

            Text {
                text: button.icon
                color: button.primary
                    ? Appearance.primaryContainerText
                    : Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(15)
                }
            }

            PanelText {
                text: button.label
                color: button.primary
                    ? Appearance.primaryContainerText
                    : Appearance.layer1Text
                font.pixelSize: Appearance.smallFontSize
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: enabled
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation { duration: Appearance.fastDuration }
        }

        Behavior on scale {
            NumberAnimation { duration: Appearance.fastDuration }
        }
    }

    component SettingCombo: Controls.ComboBox {
        id: control

        implicitHeight: Appearance.px(36)
        leftPadding: Appearance.px(10)
        rightPadding: Appearance.px(30)
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.smallFontSize
        }

        contentItem: Text {
            text: control.displayText
            color: control.enabled
                ? Appearance.layer0Text : Appearance.subtext
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font: control.font
        }

        indicator: Text {
            x: control.width - width - Appearance.px(10)
            anchors.verticalCenter: parent.verticalCenter
            text: "󰅀"
            color: Appearance.subtext
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(14)
            }
        }

        background: Rectangle {
            radius: Appearance.px(9)
            color: control.down
                ? Appearance.layer1Active : Appearance.layer1
            border.width: control.activeFocus ? 1 : 0
            border.color: Appearance.primary
        }

        delegate: Controls.ItemDelegate {
            required property var modelData

            width: control.width
            implicitHeight: Appearance.px(34)
            highlighted: control.highlightedIndex === index
            contentItem: Text {
                text: control.textRole
                    ? modelData[control.textRole] : modelData
                color: Appearance.layer0Text
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font: control.font
            }
            background: Rectangle {
                radius: Appearance.px(7)
                color: parent.highlighted
                    ? Appearance.layer1Active : "transparent"
            }
        }

        popup: Controls.Popup {
            y: control.height + Appearance.px(3)
            width: control.width
            implicitHeight: Math.min(
                contentItem.implicitHeight + Appearance.px(8),
                Appearance.px(300))
            padding: Appearance.px(4)

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.popup.visible
                    ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                Controls.ScrollIndicator.vertical:
                    Controls.ScrollIndicator {}
            }

            background: Rectangle {
                radius: Appearance.px(10)
                color: Appearance.layer2
                border.width: 1
                border.color: Appearance.outline
            }
        }
    }

    component NumberField: Controls.TextField {
        implicitWidth: Appearance.px(105)
        implicitHeight: Appearance.px(36)
        horizontalAlignment: TextInput.AlignHCenter
        color: Appearance.layer0Text
        selectionColor: Appearance.primaryContainer
        selectedTextColor: Appearance.primaryContainerText
        selectByMouse: true
        validator: IntValidator {
            bottom: -32768
            top: 32767
        }
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.smallFontSize
        }
        background: Rectangle {
            radius: Appearance.px(9)
            color: Appearance.layer1
            border.width: parent.activeFocus ? 1 : 0
            border.color: Appearance.primary
        }
    }

    component BrightnessSlider: Controls.Slider {
        id: slider

        from: 1
        to: 100
        stepSize: 1
        implicitHeight: Appearance.px(30)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: Appearance.px(8)
            radius: Appearance.fullRadius
            color: Appearance.layer1Active
            border.width: 1
            border.color: Appearance.outline

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
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Appearance.px(6)
            implicitHeight: Appearance.px(24)
            radius: Appearance.fullRadius
            color: slider.enabled
                ? Appearance.primary : Appearance.subtext
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(18)
        }
        spacing: Appearance.px(10)

        SettingsPageHeader {
            icon: "󰍹"
            title: I18n.tr("displaySettings")
            onCloseClicked: root.closeRequested()

            ActionButton {
                icon: "󰑐"
                label: I18n.tr("refresh")
                enabled: !OutputService.refreshing
                    && !OutputService.applying
                onClicked: OutputService.refresh()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: sessionHint.implicitHeight
                + Appearance.px(20)
            radius: Appearance.smallRadius
            color: Appearance.primaryContainer

            RowLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(10)
                }
                spacing: Appearance.px(8)

                Text {
                    text: "󰋼"
                    color: Appearance.primaryContainerText
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(17)
                    }
                }

                PanelText {
                    id: sessionHint
                    Layout.fillWidth: true
                    text: I18n.tr("displaySessionHint")
                    color: Appearance.primaryContainerText
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.smallFontSize
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: OutputService.errorMessage.length > 0
            implicitHeight: errorText.implicitHeight + Appearance.px(20)
            radius: Appearance.smallRadius
            color: Appearance.withAlpha(
                Theme.palette.m3errorContainer, 0.85)

            PanelText {
                id: errorText
                anchors {
                    fill: parent
                    margins: Appearance.px(10)
                }
                text: OutputService.errorMessage
                color: Theme.palette.m3onErrorContainer
                wrapMode: Text.WordWrap
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                anchors.fill: parent
                visible: OutputService.outputs.length > 0
                contentWidth: width
                contentHeight: outputColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: outputColumn

                    width: parent.width
                    spacing: Appearance.px(10)

                    Repeater {
                        model: OutputService.outputs

                        delegate: Rectangle {
                            id: outputCard

                            MouseArea {
                                anchors.fill: parent
                                onClicked: forceActiveFocus()
                            }

                            required property var modelData
                            property bool draftEnabled: modelData.enabled
                            property string draftMode:
                                modelData.currentMode
                            property real draftScale: modelData.scale
                            property string draftTransform:
                                modelData.transform
                            property bool automaticPosition:
                                !modelData.enabled
                            property int draftX: modelData.x
                            property int draftY: modelData.y
                            property bool draftVrr:
                                modelData.vrrEnabled
                            property int draftMaxBpc:
                                modelData.maxBpc
                            readonly property var brightnessState:
                                BrightnessService.stateFor(modelData.name)
                            readonly property var scaleModel:
                                root.scaleOptions(modelData.scale)

                            Layout.fillWidth: true
                            implicitHeight: cardContent.implicitHeight
                                + Appearance.px(24)
                            radius: Appearance.normalRadius
                            color: Appearance.layer3
                            border.width: 1
                            border.color: draftEnabled
                                ? Appearance.outline
                                : Appearance.layer0Border

                            ColumnLayout {
                                id: cardContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Appearance.px(12)
                                }
                                spacing: Appearance.px(11)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.px(10)

                                    Rectangle {
                                        implicitWidth: Appearance.px(44)
                                        implicitHeight: Appearance.px(44)
                                        radius: Appearance.px(12)
                                        color: outputCard.draftEnabled
                                            ? Appearance.primaryContainer
                                            : Appearance.layer1Active

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰍹"
                                            color: outputCard.draftEnabled
                                                ? Appearance.primaryContainerText
                                                : Appearance.subtext
                                            font {
                                                family: Appearance.iconFontFamily
                                                pixelSize: Appearance.px(24)
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        PanelText {
                                            Layout.fillWidth: true
                                            text: outputCard.modelData.name
                                            color: Appearance.layer0Text
                                            elide: Text.ElideRight
                                            font {
                                                pixelSize:
                                                    Appearance.largeFontSize
                                                weight: Font.DemiBold
                                            }
                                        }

                                        PanelText {
                                            Layout.fillWidth: true
                                            text: (outputCard.modelData.make
                                                + " "
                                                + outputCard.modelData.model)
                                                .trim()
                                            color: Appearance.subtext
                                            elide: Text.ElideRight
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: statusText.implicitWidth
                                            + Appearance.px(16)
                                        implicitHeight: Appearance.px(26)
                                        radius: Appearance.fullRadius
                                        color: outputCard.draftEnabled
                                            ? Appearance.primaryContainer
                                            : Appearance.layer1

                                        PanelText {
                                            id: statusText
                                            anchors.centerIn: parent
                                            text: outputCard.draftEnabled
                                                ? I18n.tr("displayConnected")
                                                : I18n.tr("displayDisabled")
                                            color: outputCard.draftEnabled
                                                ? Appearance.primaryContainerText
                                                : Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }
                                    }

                                    SettingSwitch {
                                        checked: outputCard.draftEnabled
                                        enabled: !OutputService.applying
                                        onToggled: checked =>
                                            outputCard.draftEnabled = checked
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 1
                                    color: Appearance.outline
                                    opacity: 0.55
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.px(2)
                                    enabled: outputCard.draftEnabled
                                    opacity: enabled ? 1 : 0.45

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Appearance.px(10)

                                        Text {
                                            text: "󰃠"
                                            color: outputCard.brightnessState
                                                    .available
                                                ? Appearance.primary
                                                : Appearance.subtext
                                            font {
                                                family:
                                                    Appearance.iconFontFamily
                                                pixelSize: Appearance.px(19)
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            PanelText {
                                                Layout.fillWidth: true
                                                text: I18n.tr("brightness")
                                                color: Appearance.layer0Text
                                            }

                                            PanelText {
                                                Layout.fillWidth: true
                                                visible: text.length > 0
                                                text: outputCard.brightnessState
                                                    .error
                                                    || outputCard
                                                        .brightnessState.reason
                                                color: outputCard
                                                        .brightnessState.error
                                                    ? Theme.palette.m3error
                                                    : Appearance.subtext
                                                elide: Text.ElideRight
                                                font.pixelSize:
                                                    Appearance.smallFontSize
                                            }
                                        }

                                        PanelText {
                                            Layout.preferredWidth:
                                                Appearance.px(48)
                                            horizontalAlignment: Text.AlignRight
                                            text: outputCard.brightnessState
                                                    .available
                                                ? Math.round(outputCard
                                                    .brightnessState.percent)
                                                    + "%"
                                                : "—"
                                            color: Appearance.subtext
                                        }
                                    }

                                    BrightnessSlider {
                                        Layout.fillWidth: true
                                        enabled: outputCard.brightnessState
                                            .available
                                        value: outputCard.brightnessState
                                                .available
                                            ? outputCard.brightnessState
                                                .percent : 1
                                        onMoved:
                                            BrightnessService.setBrightness(
                                                outputCard.modelData.name,
                                                value)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.px(10)
                                    enabled: outputCard.draftEnabled
                                    opacity: enabled ? 1 : 0.45

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Appearance.px(4)

                                        PanelText {
                                            text: I18n.tr(
                                                "resolutionRefresh")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        SettingCombo {
                                            Layout.fillWidth: true
                                            model: outputCard.modelData.modes
                                            textRole: "label"
                                            valueRole: "value"
                                            currentIndex:
                                                root.indexForValue(
                                                    model,
                                                    outputCard.draftMode)
                                            onActivated:
                                                outputCard.draftMode
                                                    = currentValue
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth:
                                            Appearance.px(115)
                                        spacing: Appearance.px(4)

                                        PanelText {
                                            text: I18n.tr("displayScale")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        SettingCombo {
                                            Layout.fillWidth: true
                                            model: outputCard.scaleModel
                                            textRole: "label"
                                            valueRole: "value"
                                            currentIndex:
                                                root.indexForValue(
                                                    model,
                                                    outputCard.draftScale)
                                            onActivated:
                                                outputCard.draftScale
                                                    = currentValue
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth:
                                            Appearance.px(175)
                                        spacing: Appearance.px(4)

                                        PanelText {
                                            text: I18n.tr("orientation")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        SettingCombo {
                                            Layout.fillWidth: true
                                            model: root.transformOptions
                                            textRole: "label"
                                            valueRole: "value"
                                            currentIndex:
                                                root.indexForValue(
                                                    model,
                                                    outputCard.draftTransform)
                                            onActivated:
                                                outputCard.draftTransform
                                                    = currentValue
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.px(10)
                                    enabled: outputCard.draftEnabled
                                    opacity: enabled ? 1 : 0.45

                                    ColumnLayout {
                                        spacing: Appearance.px(4)

                                        PanelText {
                                            text: I18n.tr("positionX")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        NumberField {
                                            text: String(
                                                outputCard.draftX)
                                            enabled:
                                                !outputCard.automaticPosition
                                            onTextEdited:
                                                outputCard.draftX
                                                    = Number(text) || 0
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: Appearance.px(4)

                                        PanelText {
                                            text: I18n.tr("positionY")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        NumberField {
                                            text: String(
                                                outputCard.draftY)
                                            enabled:
                                                !outputCard.automaticPosition
                                            onTextEdited:
                                                outputCard.draftY
                                                    = Number(text) || 0
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth:
                                            Appearance.px(105)
                                        spacing: Appearance.px(5)

                                        PanelText {
                                            text: I18n.tr(
                                                "automaticPosition")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        SettingSwitch {
                                            checked: outputCard
                                                .automaticPosition
                                            onToggled: checked =>
                                                outputCard
                                                    .automaticPosition
                                                        = checked
                                        }
                                    }

                                    ColumnLayout {
                                        visible: outputCard.modelData
                                            .vrrSupported
                                        Layout.preferredWidth:
                                            Appearance.px(120)
                                        spacing: Appearance.px(5)

                                        PanelText {
                                            text: I18n.tr(
                                                "variableRefreshRate")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        SettingSwitch {
                                            checked:
                                                outputCard.draftVrr
                                            onToggled: checked =>
                                                outputCard.draftVrr
                                                    = checked
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Appearance.px(4)

                                        PanelText {
                                            text: I18n.tr("colorDepth")
                                            color: Appearance.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        SettingCombo {
                                            Layout.fillWidth: true
                                            model: root.bpcOptions
                                            textRole: "label"
                                            valueRole: "value"
                                            currentIndex:
                                                root.indexForValue(
                                                    model,
                                                    outputCard.draftMaxBpc)
                                            onActivated:
                                                outputCard.draftMaxBpc
                                                    = currentValue
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: outputCard.modelData.enabled
                                            ? outputCard.modelData
                                                .logicalWidth
                                                + " × "
                                                + outputCard.modelData
                                                    .logicalHeight
                                                + "  @  "
                                                + outputCard.modelData.x
                                                + ", "
                                                + outputCard.modelData.y
                                            : I18n.tr("displayDisabled")
                                        color: Appearance.subtext
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }

                                    ActionButton {
                                        primary: true
                                        icon: OutputService.applying
                                            ? "󰦖" : "󰄬"
                                        label: OutputService.applying
                                            ? I18n.tr("applying")
                                            : I18n.tr("apply")
                                        enabled: !OutputService.applying
                                            && !OutputService.refreshing
                                            && OutputService
                                                .persistenceReady
                                        onClicked:
                                            OutputService.applyOutput(
                                                outputCard.modelData.name,
                                                outputCard.draftEnabled,
                                                outputCard.draftMode,
                                                outputCard.draftScale,
                                                outputCard.draftTransform,
                                                outputCard
                                                    .automaticPosition,
                                                outputCard.draftX,
                                                outputCard.draftY,
                                                outputCard.draftVrr,
                                                outputCard.draftMaxBpc)
                                    }
                                }
                            }
                        }
                    }
                }

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: !OutputService.refreshing
                    && OutputService.outputs.length === 0
                spacing: Appearance.px(8)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰶐"
                    color: Appearance.primary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(44)
                    }
                }

                PanelText {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("noOutputs")
                    color: Appearance.subtext
                }
            }

            Controls.BusyIndicator {
                anchors.centerIn: parent
                visible: OutputService.refreshing
                    && OutputService.outputs.length === 0
                running: visible
            }
        }
    }
}
