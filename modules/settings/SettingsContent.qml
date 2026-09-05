pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

// Content pane for the Niri-managed settings window.
Item {
    id: root

    signal closeRequested
    property string weatherLocationDraft:
        ShellSettings.weatherLocationName
    property string weatherLatitudeDraft:
        Number(ShellSettings.weatherLatitude).toFixed(5)
    property string weatherLongitudeDraft:
        Number(ShellSettings.weatherLongitude).toFixed(5)
    property string barFontFamilyDraft: ShellSettings.barFontFamily
    property string monospaceFontFamilyDraft:
        ShellSettings.monospaceFontFamily
    property int barFontSizeDraft: ShellSettings.barFontSize
    property real scaleDraft: ShellSettings.scale
    readonly property bool barAppearanceValid:
        barFontFamilyDraft.trim().length > 0
            && monospaceFontFamilyDraft.trim().length > 0
    readonly property bool barAppearanceDirty:
        barFontFamilyDraft.trim() !== ShellSettings.barFontFamily
            || monospaceFontFamilyDraft.trim()
                !== ShellSettings.monospaceFontFamily
            || barFontSizeDraft !== ShellSettings.barFontSize
            || Math.abs(scaleDraft - ShellSettings.scale) > 0.001
    readonly property bool weatherCoordinatesValid: {
        const latitude = Number(weatherLatitudeDraft);
        const longitude = Number(weatherLongitudeDraft);
        return weatherLatitudeDraft.trim() !== ""
            && weatherLongitudeDraft.trim() !== ""
            && Number.isFinite(latitude)
            && Number.isFinite(longitude)
            && latitude >= -90 && latitude <= 90
            && longitude >= -180 && longitude <= 180;
    }
    readonly property var weekStartOptions: [
        { value: -1, label: I18n.tr("followLocale") },
        { value: 1, label: I18n.tr("monday") },
        { value: 0, label: I18n.tr("sunday") },
        { value: 6, label: I18n.tr("saturday") }
    ]

    function filteredFontFamilies(families, query, showAll) {
        const needle = showAll ? "" : String(query).trim().toLowerCase();
        const prefixMatches = [];
        const containsMatches = [];
        for (let index = 0; index < families.length; ++index) {
            const family = String(families[index]);
            const lowerFamily = family.toLowerCase();
            if (needle && !lowerFamily.includes(needle))
                continue;
            if (!needle || lowerFamily.startsWith(needle))
                prefixMatches.push(family);
            else
                containsMatches.push(family);
        }
        return prefixMatches.concat(containsMatches).slice(0, 100);
    }

    function applyBarAppearance() {
        if (!barAppearanceValid)
            return;

        ShellSettings.barFontFamily = barFontFamilyDraft.trim();
        ShellSettings.monospaceFontFamily =
            monospaceFontFamilyDraft.trim();
        ShellSettings.barFontSize = Math.round(barFontSizeDraft);
        // Apply scale last so the settings layout only moves once, after all
        // other draft values have already been committed.
        ShellSettings.scale = scaleDraft;
    }
    FileDialog {
        id: avatarFileDialog

        title: I18n.tr("chooseAvatar")
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp)"]
        onAccepted: {
            ShellSettings.userAvatarPath =
                UserService.stripFileProtocol(selectedFile);
        }
    }

    ColorDialog {
        id: screenCornerColorDialog

        title: I18n.tr("screenCornerColor")
        onAccepted: {
            ShellSettings.screenCornerColor = selectedColor.toString();
        }
    }

    Connections {
        target: ShellSettings

        function onWeatherLocationNameChanged() {
            if (!weatherLocationInput.activeFocus)
                root.weatherLocationDraft =
                    ShellSettings.weatherLocationName;
        }

        function onWeatherLatitudeChanged() {
            if (!weatherLatitudeInput.activeFocus)
                root.weatherLatitudeDraft =
                    Number(ShellSettings.weatherLatitude).toFixed(5);
        }

        function onWeatherLongitudeChanged() {
            if (!weatherLongitudeInput.activeFocus)
                root.weatherLongitudeDraft =
                    Number(ShellSettings.weatherLongitude).toFixed(5);
        }
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
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

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
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

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
        }

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

    component FontSelector: Item {
        id: selector

        required property string currentValue
        property string draftText: currentValue
        property bool browseAll: false
        readonly property var fontFamilies: Qt.fontFamilies()
        readonly property var filteredFamilies:
            root.filteredFontFamilies(fontFamilies, draftText, browseAll)
        signal valueEdited(string value)

        implicitHeight: Appearance.px(36)

        function openSuggestions(showAll) {
            const wasOpened = fontPopup.opened;
            browseAll = showAll;
            fontPopup.updatePlacement();
            if (!wasOpened) {
                fontList.currentIndex = filteredFamilies.length > 0 ? 0 : -1;
                fontPopup.open();
            } else if (fontList.currentIndex >= filteredFamilies.length) {
                fontList.currentIndex = filteredFamilies.length - 1;
            }
        }

        function choose(value) {
            draftText = value;
            valueEdited(value);
            fontPopup.close();
        }

        onCurrentValueChanged: {
            if (!fontInput.activeFocus)
                draftText = currentValue;
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.px(9)
            color: Appearance.layer1
            border.width: fontInput.activeFocus || fontPopup.opened ? 1 : 0
            border.color: Appearance.primary

            Controls.TextField {
                id: fontInput

                anchors {
                    fill: parent
                    leftMargin: Appearance.px(10)
                    rightMargin: Appearance.px(34)
                }
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                color: Appearance.layer0Text
                selectionColor: Appearance.primaryContainer
                selectedTextColor: Appearance.primaryContainerText
                selectByMouse: true
                text: selector.draftText
                background: null
                font {
                    family: selector.draftText.trim()
                        || Appearance.fontFamily
                    pixelSize: Appearance.fontSize
                }

                onTextEdited: {
                    selector.browseAll = false;
                    selector.draftText = text;
                    selector.valueEdited(text);
                    selector.openSuggestions(false);
                }
                onActiveFocusChanged: {
                    if (activeFocus)
                        selector.openSuggestions(false);
                }
                onAccepted: {
                    if (fontPopup.opened && fontList.currentIndex >= 0) {
                        selector.choose(selector.filteredFamilies[
                            fontList.currentIndex]);
                    } else {
                        selector.valueEdited(text.trim());
                        fontPopup.close();
                    }
                }
                Keys.onDownPressed: event => {
                    const wasOpened = fontPopup.opened;
                    selector.openSuggestions(false);
                    if (wasOpened) {
                        fontList.currentIndex = Math.min(
                            selector.filteredFamilies.length - 1,
                            Math.max(0, fontList.currentIndex + 1));
                    }
                    event.accepted = true;
                }
                Keys.onUpPressed: event => {
                    const wasOpened = fontPopup.opened;
                    selector.openSuggestions(false);
                    if (wasOpened) {
                        fontList.currentIndex = Math.max(0,
                            fontList.currentIndex - 1);
                    } else if (selector.filteredFamilies.length > 0) {
                        fontList.currentIndex =
                            selector.filteredFamilies.length - 1;
                    }
                    event.accepted = true;
                }
            }

            Text {
                anchors {
                    right: parent.right
                    rightMargin: Appearance.px(10)
                    verticalCenter: parent.verticalCenter
                }
                text: fontPopup.opened ? "󰅃" : "󰅀"
                color: Appearance.subtext
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(14)
                }
            }

            MouseArea {
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }
                width: Appearance.px(34)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const wasOpened = fontPopup.opened;
                    fontInput.forceActiveFocus();
                    if (wasOpened)
                        fontPopup.close();
                    else
                        selector.openSuggestions(true);
                }
            }
        }

        Controls.Popup {
            id: fontPopup

            parent: selector
            x: 0
            width: selector.width
            height: Math.min(Appearance.px(260), Math.max(
                Appearance.px(42),
                selector.filteredFamilies.length * Appearance.px(34)
                    + topPadding + bottomPadding))
            padding: Appearance.px(4)
            closePolicy: Controls.Popup.CloseOnEscape
                | Controls.Popup.CloseOnPressOutsideParent
            onClosed: selector.browseAll = false

            function updatePlacement() {
                const window = Window.window;
                if (!window) {
                    y = selector.height + Appearance.px(4);
                    return;
                }

                const scenePosition = selector.mapToItem(null, 0, 0);
                const spaceAbove = scenePosition.y;
                const spaceBelow = window.height - scenePosition.y
                    - selector.height;
                const requiredSpace = height + Appearance.px(8);
                y = spaceBelow < requiredSpace
                        && spaceAbove >= requiredSpace
                    ? -height - Appearance.px(4)
                    : selector.height + Appearance.px(4);
            }

            contentItem: ListView {
                id: fontList

                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: selector.filteredFamilies
                currentIndex: -1

                delegate: Controls.ItemDelegate {
                    id: fontDelegate

                    required property string modelData
                    required property int index
                    width: fontList.width
                    implicitHeight: Appearance.px(34)
                    highlighted: fontList.currentIndex === index

                    contentItem: Text {
                        text: fontDelegate.modelData
                        color: Appearance.layer0Text
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font {
                            family: fontDelegate.modelData
                            pixelSize: Appearance.smallFontSize
                        }
                    }
                    background: Rectangle {
                        radius: Appearance.px(7)
                        color: fontDelegate.highlighted
                            ? Appearance.layer1Active : "transparent"
                    }
                    onClicked: selector.choose(modelData)
                }

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

    component MetricChoice: Rectangle {
        id: metricChoice

        required property string icon
        required property string label
        required property string value
        required property bool selected
        signal toggled

        Layout.fillWidth: true
        implicitHeight: Appearance.px(68)
        radius: Appearance.smallRadius
        color: selected
            ? Appearance.primaryContainer
            : metricChoiceArea.containsMouse
                ? Appearance.layer1Active : Appearance.layer1
        border.width: 1
        border.color: selected
            ? Appearance.primary : Appearance.outline
        scale: metricChoiceArea.pressed ? 0.98 : 1

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(12)
                rightMargin: Appearance.px(12)
            }
            spacing: Appearance.px(10)

            Rectangle {
                implicitWidth: Appearance.px(38)
                implicitHeight: Appearance.px(38)
                radius: Appearance.fullRadius
                color: metricChoice.selected
                    ? Appearance.primary
                    : Appearance.layer1Active

                Text {
                    anchors.centerIn: parent
                    text: metricChoice.icon
                    color: metricChoice.selected
                        ? Theme.palette.m3onPrimary
                        : Appearance.primary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(19)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PanelText {
                    Layout.fillWidth: true
                    text: metricChoice.label
                    color: metricChoice.selected
                        ? Appearance.primaryContainerText
                        : Appearance.layer0Text
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                }

                PanelText {
                    text: metricChoice.value
                    color: metricChoice.selected
                        ? Appearance.primaryContainerText
                        : Appearance.subtext
                    font.pixelSize: Appearance.smallFontSize
                }
            }

            Text {
                visible: metricChoice.selected
                text: "󰄬"
                color: Appearance.primaryContainerText
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(15)
                }
            }
        }

        MouseArea {
            id: metricChoiceArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: metricChoice.toggled()
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

    component ChoiceChip: Rectangle {
        id: choiceChip

        required property string label
        required property bool selected
        signal chosen

        Layout.fillWidth: true
        implicitHeight: Appearance.px(36)
        radius: Appearance.px(9)
        color: selected
            ? Appearance.primaryContainer
            : choiceMouse.containsMouse
                ? Appearance.layer1Active : Appearance.layer1
        border.width: 1
        border.color: selected
            ? Appearance.primary : Appearance.outline
        scale: choiceMouse.pressed ? 0.97 : 1

        PanelText {
            anchors {
                fill: parent
                leftMargin: Appearance.px(7)
                rightMargin: Appearance.px(7)
            }
            text: choiceChip.label
            color: choiceChip.selected
                ? Appearance.primaryContainerText
                : Appearance.layer1Text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font {
                pixelSize: Appearance.smallFontSize
                weight: choiceChip.selected
                    ? Font.DemiBold : Font.Normal
            }
        }

        MouseArea {
            id: choiceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choiceChip.chosen()
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

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
        }

        PanelText {
            Layout.preferredWidth: Appearance.px(
                I18n.language === "en_US" ? 150 : 118)
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

    component FormatRow: RowLayout {
        id: formatRow

        required property string label
        required property string currentValue
        required property string hint
        property string draftValue: currentValue
        signal accepted(string value)

        Layout.fillWidth: true
        spacing: Appearance.px(10)

        function commit() {
            const format = draftValue.trim();
            if (format) {
                draftValue = format;
                accepted(format);
            } else {
                draftValue = currentValue;
            }
        }

        onCurrentValueChanged: {
            if (!formatInput.activeFocus)
                draftValue = currentValue;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
        }

        ColumnLayout {
            readonly property int targetWidth: Appearance.px(
                I18n.language === "en_US" ? 260 : 230)

            Layout.preferredWidth: targetWidth
            Layout.minimumWidth: Appearance.px(180)
            Layout.maximumWidth: targetWidth
            spacing: Appearance.px(1)

            PanelText {
                Layout.fillWidth: true
                text: formatRow.label
                color: Appearance.layer0Text
            }

            PanelText {
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                text: formatRow.hint
                color: Appearance.subtext
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.smallFontSize
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: Appearance.px(160)
            Layout.preferredWidth: Appearance.px(240)
            implicitHeight: Appearance.px(36)
            radius: Appearance.px(9)
            color: Appearance.layer1
            border.width: formatInput.activeFocus ? 1 : 0
            border.color: Appearance.primary

            Controls.TextField {
                id: formatInput

                anchors {
                    fill: parent
                    leftMargin: Appearance.px(10)
                    rightMargin: Appearance.px(10)
                }
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                color: Appearance.layer0Text
                selectionColor: Appearance.primaryContainer
                selectedTextColor: Appearance.primaryContainerText
                selectByMouse: true
                persistentSelection: true
                text: formatRow.draftValue
                background: null
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.fontSize
                }
                onTextEdited: formatRow.draftValue = text
                onAccepted: formatRow.commit()
                onEditingFinished: formatRow.commit()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
        }

        SettingsPageHeader {
            id: pageHeader
            height: implicitHeight
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Appearance.px(18)
            }
            icon: "󰒓"
            title: I18n.tr("quickSettings")
            onCloseClicked: root.closeRequested()
        }

        Flickable {
            id: flickable
            anchors {
                top: pageHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Appearance.px(5)
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

            MouseArea {
                anchors.fill: parent
                onClicked: forceActiveFocus()
            }

            ColumnLayout {
                id: settingsColumn
                width: flickable.width - Appearance.px(10)
                spacing: Appearance.px(9)

                SectionTitle {
                    icon: "󰀄"
                    title: I18n.tr("userProfile")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(14)

                        UserAvatar {
                            implicitSize: Appearance.px(70)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(3)

                            PanelText {
                                Layout.fillWidth: true
                                text: UserService.displayName
                                color: Appearance.layer0Text
                                elide: Text.ElideRight
                                font {
                                    pixelSize: Appearance.largeFontSize
                                    weight: Font.DemiBold
                                }
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: UserService.loginName
                                    ? "@" + UserService.loginName
                                    : I18n.tr("user")
                                color: Appearance.subtext
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(8)

                        Rectangle {
                            implicitWidth: chooseAvatarRow.implicitWidth
                                + Appearance.px(20)
                            implicitHeight: Appearance.px(34)
                            radius: Appearance.px(9)
                            color: chooseAvatarArea.containsMouse
                                ? Appearance.layer1Active
                                : Appearance.layer1

                            RowLayout {
                                id: chooseAvatarRow
                                anchors.centerIn: parent
                                spacing: Appearance.px(6)

                                Text {
                                    text: "󰈔"
                                    color: Appearance.primary
                                    font {
                                        family:
                                            Appearance.iconFontFamily
                                        pixelSize: Appearance.px(15)
                                    }
                                }

                                PanelText {
                                    text: I18n.tr("chooseAvatar")
                                    font.pixelSize:
                                        Appearance.smallFontSize
                                }
                            }

                            MouseArea {
                                id: chooseAvatarArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: avatarFileDialog.open()
                            }
                        }

                        Rectangle {
                            implicitWidth: systemProfileRow.implicitWidth
                                + Appearance.px(20)
                            implicitHeight: Appearance.px(34)
                            radius: Appearance.px(9)
                            color: systemProfileArea.containsMouse
                                ? Appearance.layer1Active
                                : Appearance.layer1

                            RowLayout {
                                id: systemProfileRow
                                anchors.centerIn: parent
                                spacing: Appearance.px(6)

                                Text {
                                    text: "󰑐"
                                    color: Appearance.primary
                                    font {
                                        family:
                                            Appearance.iconFontFamily
                                        pixelSize: Appearance.px(15)
                                    }
                                }

                                PanelText {
                                    text:
                                        I18n.tr("restoreSystemProfile")
                                    font.pixelSize:
                                        Appearance.smallFontSize
                                }
                            }

                            MouseArea {
                                id: systemProfileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ShellSettings.userAvatarPath = "";
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                SectionTitle {
                    icon: "󰌾"
                    title: I18n.tr("session")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                Layout.fillWidth: true
                                text: I18n.tr("lockOnStartup")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: I18n.tr("lockOnStartupHint")
                                color: Appearance.subtext
                                wrapMode: Text.WordWrap
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.lockOnStartup
                            onToggled: checked => {
                                ShellSettings.lockOnStartup = checked;
                            }
                        }
                    }
                }

                SectionTitle {
                    icon: "󰍛"
                    title: I18n.tr("performanceMonitor")
                }

                SettingCard {
                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("performanceMonitorHint")
                        color: Appearance.subtext
                        wrapMode: Text.WordWrap
                        font.pixelSize: Appearance.smallFontSize
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(8)

                        MetricChoice {
                            icon: "󰻠"
                            label: I18n.tr("cpuUsage")
                            value: Math.round(
                                ResourceService.cpuUsage * 100) + "%"
                            selected: ShellSettings.showCpuUsage
                            onToggled:
                                ShellSettings.showCpuUsage = !selected
                        }

                        MetricChoice {
                            icon: "󰍛"
                            label: I18n.tr("memoryUsage")
                            value: Math.round(
                                ResourceService.memoryUsage * 100) + "%"
                            selected: ShellSettings.showMemoryUsage
                            onToggled:
                                ShellSettings.showMemoryUsage = !selected
                        }

                        MetricChoice {
                            icon: "󰔏"
                            label: I18n.tr("cpuTemperature")
                            value: ResourceService.temperatureAvailable
                                ? Math.round(
                                    ResourceService.cpuTemperature) + "°C"
                                : "--°C"
                            selected: ShellSettings.showCpuTemperature
                            onToggled:
                                ShellSettings.showCpuTemperature = !selected
                        }
                    }
                }

                SectionTitle {
                    icon: "󰖐"
                    title: I18n.tr("weatherLocation")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(9)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(3)

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Appearance.px(36)
                                radius: Appearance.px(9)
                                color: Appearance.layer1
                                border.width:
                                    weatherLocationInput.activeFocus
                                        ? 1 : 0
                                border.color: Appearance.primary

                                Controls.TextField {
                                    id: weatherLocationInput

                                    anchors {
                                        fill: parent
                                        leftMargin: Appearance.px(10)
                                        rightMargin: Appearance.px(10)
                                    }
                                    padding: 0
                                    verticalAlignment:
                                        TextInput.AlignVCenter
                                    color: Appearance.layer0Text
                                    selectionColor:
                                        Appearance.primaryContainer
                                    selectedTextColor:
                                        Appearance.primaryContainerText
                                    selectByMouse: true
                                    persistentSelection: true
                                    text: root.weatherLocationDraft
                                    placeholderText:
                                        I18n.tr("weatherLocationHint")
                                    placeholderTextColor:
                                        Appearance.subtext
                                    background: null
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.fontSize
                                    }
                                    onTextEdited:
                                        root.weatherLocationDraft = text
                                    onAccepted: {
                                        WeatherService.searchLocation(
                                            root.weatherLocationDraft);
                                    }
                                }
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: {
                                    switch (WeatherService
                                            .locationSearchStatus) {
                                    case "searching":
                                        return I18n.tr(
                                            "locationSearching");
                                    case "notFound":
                                        return I18n.tr(
                                            "locationNotFound");
                                    case "failed":
                                        return I18n.tr(
                                            "locationSearchFailed");
                                    default:
                                        return ShellSettings
                                            .weatherLocationName;
                                    }
                                }
                                color: WeatherService
                                        .locationSearchStatus
                                        === "failed"
                                        || WeatherService
                                            .locationSearchStatus
                                            === "notFound"
                                    ? Theme.palette.m3error
                                    : Appearance.subtext
                                elide: Text.ElideRight
                                font.pixelSize:
                                    Appearance.smallFontSize
                            }
                        }

                        Rectangle {
                            implicitWidth: weatherSearchRow.implicitWidth
                                + Appearance.px(20)
                            implicitHeight: Appearance.px(36)
                            radius: Appearance.px(9)
                            color: weatherSearchArea.containsMouse
                                    && weatherSearchArea.enabled
                                ? Appearance.layer1Active
                                : Appearance.primaryContainer
                            opacity: weatherSearchArea.enabled ? 1 : 0.5

                            RowLayout {
                                id: weatherSearchRow
                                anchors.centerIn: parent
                                spacing: Appearance.px(6)

                                Item {
                                    implicitWidth: Appearance.px(16)
                                    implicitHeight: Appearance.px(16)

                                    Text {
                                        anchors.centerIn: parent
                                        visible: WeatherService
                                                .locationSearchStatus
                                            !== "searching"
                                        text: "󰍉"
                                        rotation: 0
                                        color: Appearance
                                            .primaryContainerText
                                        font {
                                            family: Appearance
                                                .iconFontFamily
                                            pixelSize:
                                                Appearance.px(15)
                                        }
                                    }

                                    Text {
                                        id: locationLoadingIcon

                                        anchors.centerIn: parent
                                        visible: WeatherService
                                                .locationSearchStatus
                                            === "searching"
                                        text: "󰔟"
                                        color: Appearance
                                            .primaryContainerText
                                        font {
                                            family: Appearance
                                                .iconFontFamily
                                            pixelSize:
                                                Appearance.px(15)
                                        }

                                        RotationAnimator {
                                            target: locationLoadingIcon
                                            running:
                                                locationLoadingIcon.visible
                                            from: 0
                                            to: 360
                                            duration: 900
                                            loops:
                                                Animation.Infinite
                                        }
                                    }
                                }

                                PanelText {
                                    text: I18n.tr("searchLocation")
                                    color:
                                        Appearance.primaryContainerText
                                    font.pixelSize:
                                        Appearance.smallFontSize
                                }
                            }

                            MouseArea {
                                id: weatherSearchArea
                                anchors.fill: parent
                                enabled: WeatherService
                                        .locationSearchStatus
                                    !== "searching"
                                    && root.weatherLocationDraft
                                        .trim().length >= 2
                                hoverEnabled: true
                                cursorShape: enabled
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor
                                onClicked:
                                    WeatherService.searchLocation(
                                        root.weatherLocationDraft)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance.outline
                        opacity: 0.65
                    }

                    PanelText {
                        text: I18n.tr("directCoordinates")
                        color: Appearance.layer0Text
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(9)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(3)

                            PanelText {
                                text: I18n.tr("latitude")
                                color: Appearance.subtext
                                font.pixelSize:
                                    Appearance.smallFontSize
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Appearance.px(36)
                                radius: Appearance.px(9)
                                color: Appearance.layer1
                                border.width:
                                    weatherLatitudeInput.activeFocus
                                        ? 1 : 0
                                border.color: Appearance.primary

                                Controls.TextField {
                                    id: weatherLatitudeInput

                                    anchors {
                                        fill: parent
                                        leftMargin: Appearance.px(10)
                                        rightMargin: Appearance.px(10)
                                    }
                                    padding: 0
                                    verticalAlignment:
                                        TextInput.AlignVCenter
                                    color: Appearance.layer0Text
                                    selectionColor:
                                        Appearance.primaryContainer
                                    selectedTextColor:
                                        Appearance.primaryContainerText
                                    selectByMouse: true
                                    persistentSelection: true
                                    inputMethodHints:
                                        Qt.ImhFormattedNumbersOnly
                                    text: root.weatherLatitudeDraft
                                    placeholderText: "31.23040"
                                    placeholderTextColor:
                                        Appearance.subtext
                                    background: null
                                    validator: DoubleValidator {
                                        bottom: -90
                                        top: 90
                                        decimals: 6
                                        notation:
                                            DoubleValidator
                                                .StandardNotation
                                    }
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.fontSize
                                    }
                                    onTextEdited:
                                        root.weatherLatitudeDraft = text
                                    onAccepted: {
                                        if (root.weatherCoordinatesValid)
                                            WeatherService.setCoordinates(
                                                root.weatherLatitudeDraft,
                                                root.weatherLongitudeDraft);
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(3)

                            PanelText {
                                text: I18n.tr("longitude")
                                color: Appearance.subtext
                                font.pixelSize:
                                    Appearance.smallFontSize
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Appearance.px(36)
                                radius: Appearance.px(9)
                                color: Appearance.layer1
                                border.width:
                                    weatherLongitudeInput.activeFocus
                                        ? 1 : 0
                                border.color: Appearance.primary

                                Controls.TextField {
                                    id: weatherLongitudeInput

                                    anchors {
                                        fill: parent
                                        leftMargin: Appearance.px(10)
                                        rightMargin: Appearance.px(10)
                                    }
                                    padding: 0
                                    verticalAlignment:
                                        TextInput.AlignVCenter
                                    color: Appearance.layer0Text
                                    selectionColor:
                                        Appearance.primaryContainer
                                    selectedTextColor:
                                        Appearance.primaryContainerText
                                    selectByMouse: true
                                    persistentSelection: true
                                    inputMethodHints:
                                        Qt.ImhFormattedNumbersOnly
                                    text: root.weatherLongitudeDraft
                                    placeholderText: "121.47370"
                                    placeholderTextColor:
                                        Appearance.subtext
                                    background: null
                                    validator: DoubleValidator {
                                        bottom: -180
                                        top: 180
                                        decimals: 6
                                        notation:
                                            DoubleValidator
                                                .StandardNotation
                                    }
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.fontSize
                                    }
                                    onTextEdited:
                                        root.weatherLongitudeDraft = text
                                    onAccepted: {
                                        if (root.weatherCoordinatesValid)
                                            WeatherService.setCoordinates(
                                                root.weatherLatitudeDraft,
                                                root.weatherLongitudeDraft);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignBottom
                            implicitWidth: coordinateApplyRow.implicitWidth
                                + Appearance.px(20)
                            implicitHeight: Appearance.px(36)
                            radius: Appearance.px(9)
                            color: coordinateApplyArea.containsMouse
                                    && coordinateApplyArea.enabled
                                ? Appearance.layer1Active
                                : Appearance.primaryContainer
                            opacity: coordinateApplyArea.enabled ? 1 : 0.5

                            RowLayout {
                                id: coordinateApplyRow
                                anchors.centerIn: parent
                                spacing: Appearance.px(6)

                                Text {
                                    text: "󰍎"
                                    color:
                                        Appearance.primaryContainerText
                                    font {
                                        family:
                                            Appearance.iconFontFamily
                                        pixelSize: Appearance.px(15)
                                    }
                                }

                                PanelText {
                                    text: I18n.tr("applyCoordinates")
                                    color:
                                        Appearance.primaryContainerText
                                    font.pixelSize:
                                        Appearance.smallFontSize
                                }
                            }

                            MouseArea {
                                id: coordinateApplyArea
                                anchors.fill: parent
                                enabled: root.weatherCoordinatesValid
                                hoverEnabled: true
                                cursorShape: enabled
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor
                                onClicked:
                                    WeatherService.setCoordinates(
                                        root.weatherLatitudeDraft,
                                        root.weatherLongitudeDraft)
                            }
                        }
                    }

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("coordinateRangeHint")
                        color: root.weatherCoordinatesValid
                            ? Appearance.subtext
                            : Theme.palette.m3error
                        font.pixelSize: Appearance.smallFontSize
                    }
                }

                SectionTitle {
                    icon: "󰗊"
                    title: I18n.tr("language")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(8)

                        PanelText {
                            Layout.fillWidth: true
                            text: I18n.tr("interfaceLanguage")
                            color: Appearance.layer0Text
                        }

                        Repeater {
                            model: [
                                { label: "简体中文", language: "zh_CN" },
                                { label: "English", language: "en_US" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: Appearance.px(94)
                                implicitHeight: Appearance.px(32)
                                radius: Appearance.px(9)
                                color: ShellSettings.language
                                        === modelData.language
                                    ? Appearance.primaryContainer
                                    : languageArea.containsMouse
                                        ? Appearance.layer1Active
                                        : Appearance.layer1
                                border.width: ShellSettings.language
                                        === modelData.language ? 1 : 0
                                border.color: Appearance.primary

                                PanelText {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: ShellSettings.language
                                            === modelData.language
                                        ? Appearance.primaryContainerText
                                        : Appearance.layer1Text
                                    font.pixelSize: Appearance.smallFontSize
                                }

                                MouseArea {
                                    id: languageArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ShellSettings.language =
                                            parent.modelData.language;
                                    }
                                }
                            }
                        }
                    }
                }

                SectionTitle {
                    icon: "󰔎"
                    title: I18n.tr("appearance")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(8)

                        PanelText {
                            Layout.fillWidth: true
                            text: I18n.tr("colorMode")
                            color: Appearance.layer0Text
                        }

                        Repeater {
                            model: [
                                { label: "󰖔  " + I18n.tr("light"),
                                    mode: "light" },
                                { label: "󰖙  " + I18n.tr("dark"),
                                    mode: "dark" }
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
                                text: I18n.tr("barFrostedGlass")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                text: I18n.tr("barFrostedGlassHint")
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.barFrostedGlass
                            onToggled: checked =>
                                ShellSettings.barFrostedGlass = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("barBackgroundless")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                text: I18n.tr("barBackgroundlessHint")
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.barBackgroundless
                            onToggled: checked =>
                                ShellSettings.barBackgroundless = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        opacity: ShellSettings.barFrostedGlass ? 1 : 0.42

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("monochromeAppIcons")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                text: I18n.tr("monochromeAppIconsHint")
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            enabled: ShellSettings.barFrostedGlass
                            checked: ShellSettings.monochromeAppIcons
                            onToggled: checked =>
                                ShellSettings.monochromeAppIcons = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("screenCornerColor")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                text: I18n.tr("screenCornerColorHint")
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        Rectangle {
                            id: screenCornerColorButton

                            implicitWidth: Appearance.px(138)
                            implicitHeight: Appearance.px(36)
                            radius: Appearance.px(10)
                            color: screenCornerColorMouse.containsMouse
                                ? Appearance.layer1Active : Appearance.layer1
                            border.width: 1
                            border.color: Appearance.outline

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: Appearance.px(8)
                                    rightMargin: Appearance.px(10)
                                }
                                spacing: Appearance.px(8)

                                Rectangle {
                                    Layout.preferredWidth: Appearance.px(22)
                                    Layout.preferredHeight: Appearance.px(22)
                                    radius: Appearance.px(6)
                                    color: ShellSettings.screenCornerColor
                                    border.width: 1
                                    border.color: Appearance.outline
                                }

                                PanelText {
                                    Layout.fillWidth: true
                                    text: ShellSettings.screenCornerColor
                                        .toUpperCase()
                                    color: Appearance.layer1Text
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: Appearance.smallFontSize
                                }

                                Text {
                                    text: "󰏘"
                                    color: Appearance.primary
                                    font {
                                        family: Appearance.iconFontFamily
                                        pixelSize: Appearance.px(15)
                                    }
                                }
                            }

                            MouseArea {
                                id: screenCornerColorMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    screenCornerColorDialog.selectedColor =
                                        ShellSettings.screenCornerColor;
                                    screenCornerColorDialog.open();
                                }
                            }

                            StyledToolTip {
                                visible:
                                    screenCornerColorMouse.containsMouse
                                text: I18n.tr("chooseColor")
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("showActiveWindowIcon")
                                color: Appearance.layer0Text
                            }
                            PanelText {
                                text: I18n.tr("activeWindowHint")
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(6)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("workspaceIndicatorStyle")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                text: I18n.tr("workspaceIndicatorStyleHint")
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(6)

                            Repeater {
                                model: [
                                    { value: "circle",
                                        key: "workspaceStyleCircle" },
                                    { value: "dots",
                                        key: "workspaceStyleDots" }
                                ]

                                delegate: ChoiceChip {
                                    required property var modelData

                                    label: I18n.tr(modelData.key)
                                    selected: ShellSettings
                                        .workspaceIndicatorStyle
                                            === modelData.value
                                    onChosen: ShellSettings
                                        .workspaceIndicatorStyle =
                                            modelData.value
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
                                text: I18n.tr("showEmptyWorkspaces")
                                color: Appearance.layer0Text
                            }
                            PanelText {
                                text: I18n.tr("activeWorkspaceHint")
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
                    icon: "󰛖"
                    title: I18n.tr("barFontSize")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        PanelText {
                            Layout.preferredWidth: Appearance.px(
                                I18n.language === "en_US" ? 150 : 118)
                            text: I18n.tr("font")
                        }

                        FontSelector {
                            Layout.fillWidth: true
                            currentValue: root.barFontFamilyDraft
                            onValueEdited: value => {
                                root.barFontFamilyDraft = value;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        PanelText {
                            Layout.preferredWidth: Appearance.px(
                                I18n.language === "en_US" ? 150 : 118)
                            text: I18n.tr("monospaceFont")
                        }

                        FontSelector {
                            Layout.fillWidth: true
                            currentValue: root.monospaceFontFamilyDraft
                            onValueEdited: value => {
                                root.monospaceFontFamilyDraft = value;
                            }
                        }
                    }

                    SliderRow {
                        label: I18n.tr("fontSize")
                        currentValue: root.barFontSizeDraft
                        from: 9
                        to: 24
                        stepSize: 1
                        decimals: 0
                        suffix: " px"
                        onMoved: value => {
                            root.barFontSizeDraft = Math.round(value);
                        }
                    }

                    SliderRow {
                        label: I18n.tr("overallScale")
                        currentValue: root.scaleDraft
                        from: 0.75
                        to: 1.5
                        stepSize: 0.05
                        decimals: 2
                        suffix: "×"
                        onMoved: value => root.scaleDraft = value
                    }

                    Rectangle {
                        id: confirmBarAppearanceButton

                        Layout.alignment: Qt.AlignRight
                        implicitWidth: confirmBarAppearanceRow.implicitWidth
                            + Appearance.px(22)
                        implicitHeight: Appearance.px(34)
                        radius: Appearance.px(10)
                        enabled: root.barAppearanceValid
                            && root.barAppearanceDirty
                        opacity: enabled ? 1 : 0.45
                        color: confirmBarAppearanceArea.containsMouse
                                && enabled
                            ? Appearance.primary
                            : Appearance.primaryContainer

                        RowLayout {
                            id: confirmBarAppearanceRow
                            anchors.centerIn: parent
                            spacing: Appearance.px(6)

                            Text {
                                text: "󰄬"
                                color: Appearance.primaryContainerText
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(14)
                                }
                            }

                            PanelText {
                                text: I18n.tr("confirm")
                                color: Appearance.primaryContainerText
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        MouseArea {
                            id: confirmBarAppearanceArea
                            anchors.fill: parent
                            enabled: parent.enabled
                            hoverEnabled: true
                            cursorShape: enabled
                                ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.applyBarAppearance()
                        }
                    }
                }

                SectionTitle {
                    icon: "󰅹"
                    title: I18n.tr("shadow")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("barPopupShadow")
                                color: Appearance.layer0Text
                            }
                            PanelText {
                                text: I18n.tr("shadowHint")
                                color: Appearance.subtext
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.shadowEnabled
                            onToggled: checked => {
                                ShellSettings.shadowEnabled = checked;
                            }
                        }
                    }

                    SliderRow {
                        enabled: ShellSettings.shadowEnabled
                        opacity: enabled ? 1 : 0.45
                        label: I18n.tr("blurRadius")
                        currentValue: ShellSettings.shadowBlurRadius
                        from: 0
                        to: 48
                        stepSize: 1
                        decimals: 0
                        suffix: " px"
                        onMoved: value => {
                            ShellSettings.shadowBlurRadius = Math.round(value);
                        }
                    }

                    SliderRow {
                        enabled: ShellSettings.shadowEnabled
                        opacity: enabled ? 1 : 0.45
                        label: I18n.tr("opacity")
                        currentValue: ShellSettings.shadowOpacity
                        from: 0
                        to: 0.9
                        stepSize: 0.05
                        decimals: 2
                        onMoved: value => ShellSettings.shadowOpacity = value
                    }

                    SliderRow {
                        enabled: ShellSettings.shadowEnabled
                        opacity: enabled ? 1 : 0.45
                        label: I18n.tr("verticalOffset")
                        currentValue: ShellSettings.shadowOffsetY
                        from: -12
                        to: 24
                        stepSize: 1
                        decimals: 0
                        suffix: " px"
                        onMoved: value => {
                            ShellSettings.shadowOffsetY = Math.round(value);
                        }
                    }
                }

                SectionTitle {
                    icon: "󰔛"
                    title: I18n.tr("animation")
                }

                SettingCard {
                    SliderRow {
                        label: I18n.tr("animationDuration")
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
                        text: I18n.tr("bezierCurve")
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
                    icon: "󰃭"
                    title: I18n.tr("clock")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        ColumnLayout {
                            readonly property int targetWidth: Appearance.px(
                                I18n.language === "en_US" ? 260 : 230)

                            Layout.preferredWidth: targetWidth
                            Layout.minimumWidth: Appearance.px(180)
                            Layout.maximumWidth: targetWidth
                            spacing: Appearance.px(1)

                            PanelText {
                                Layout.fillWidth: true
                                text: I18n.tr("barCenterAlignment")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                Layout.fillWidth: true
                                Layout.maximumWidth: parent.width
                                text: I18n.tr("barCenterAlignmentHint")
                                color: Appearance.subtext
                                wrapMode: Text.WordWrap
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(6)

                            Repeater {
                                model: ["group", "clock"]

                                delegate: ChoiceChip {
                                    required property string modelData

                                    // Keep translation lookup in the delegate
                                    // binding so live language changes always
                                    // update both choices.
                                    label: modelData === "group"
                                        ? I18n.tr("centerWholeGroup")
                                        : I18n.tr("centerOnClock")
                                    selected:
                                        ShellSettings.barCenterAlignment
                                            === modelData
                                    onChosen: {
                                        ShellSettings.barCenterAlignment =
                                            modelData;
                                    }
                                }
                            }
                        }
                    }

                    FormatRow {
                        label: I18n.tr("timeFormat")
                        currentValue: ShellSettings.timeFormat
                        hint: I18n.tr("timeFormatHint")
                        onAccepted: value => {
                            ShellSettings.timeFormat = value;
                        }
                    }

                    FormatRow {
                        label: I18n.tr("dateFormat")
                        currentValue: ShellSettings.dateFormat
                        hint: I18n.tr("dateFormatHint")
                        onAccepted: value => {
                            ShellSettings.dateFormat = value;
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        ColumnLayout {
                            readonly property int targetWidth: Appearance.px(
                                I18n.language === "en_US" ? 260 : 230)

                            Layout.preferredWidth: targetWidth
                            Layout.minimumWidth: Appearance.px(180)
                            Layout.maximumWidth: targetWidth
                            spacing: Appearance.px(1)

                            PanelText {
                                Layout.fillWidth: true
                                text: I18n.tr("weekStartsOn")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                Layout.fillWidth: true
                                Layout.maximumWidth: parent.width
                                text: I18n.tr("weekStartsOnHint")
                                color: Appearance.subtext
                                wrapMode: Text.WordWrap
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(6)

                            Repeater {
                                model: root.weekStartOptions

                                delegate: ChoiceChip {
                                    required property var modelData

                                    label: modelData.label
                                    selected:
                                        ShellSettings.calendarWeekStart
                                            === modelData.value
                                    onChosen: {
                                        ShellSettings.calendarWeekStart =
                                            modelData.value;
                                    }
                                }
                            }
                        }
                    }
                }

                SectionTitle {
                    icon: "󰅇"
                    title: I18n.tr("clipboardStorage")
                }

                SettingCard {
                    SliderRow {
                        label: I18n.tr("clipboardMaxEntrySize")
                        currentValue: ShellSettings.clipboardMaxEntryMb
                        from: 1
                        to: 100
                        stepSize: 1
                        decimals: 0
                        suffix: " MB"
                        onMoved: value => {
                            ShellSettings.clipboardMaxEntryMb =
                                Math.round(value);
                        }
                    }

                    SliderRow {
                        label: I18n.tr("clipboardMaxEntries")
                        currentValue: ShellSettings.clipboardMaxEntries
                        from: 10
                        to: 500
                        stepSize: 10
                        decimals: 0
                        onMoved: value => {
                            ShellSettings.clipboardMaxEntries =
                                Math.round(value);
                        }
                    }
                }

                SectionTitle {
                    icon: "󰂚"
                    title: I18n.tr("notifications")
                }

                SettingCard {
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(1)

                            PanelText {
                                text: I18n.tr("doNotDisturb")
                                color: Appearance.layer0Text
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: I18n.tr("notificationSettingsHint")
                                color: Appearance.subtext
                                wrapMode: Text.WordWrap
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        SettingSwitch {
                            checked: ShellSettings.doNotDisturb
                            onToggled: checked => {
                                ShellSettings.doNotDisturb = checked;
                            }
                        }
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
                        text: "󰑓  " + I18n.tr("restoreDefaults")
                        color: Appearance.layer1Text
                        font.pixelSize: Appearance.smallFontSize
                    }

                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellSettings.resetDefaults();
                            root.barFontFamilyDraft =
                                ShellSettings.barFontFamily;
                            root.monospaceFontFamilyDraft =
                                ShellSettings.monospaceFontFamily;
                            root.barFontSizeDraft = ShellSettings.barFontSize;
                            root.scaleDraft = ShellSettings.scale;
                        }
                    }
                }
            }
        }
    }
}
