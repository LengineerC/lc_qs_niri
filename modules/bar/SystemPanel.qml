pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    property bool embedded: false
    property bool useBarPalette: !embedded
    property bool active: visible
    property string outputName: ""
    property string expandedSection: embedded ? "wifi" : ""
    property bool wifiPasswordVisible: false
    readonly property var brightnessState:
        BrightnessService.stateFor(outputName)
    signal closeRequested

    BarPalette {
        id: panelPalette
        enabled: root.useBarPalette
    }

    function submitWifiPassword() {
        const ssid = SystemService.passwordRequestedSsid;
        if (!ssid || !wifiPassword.text || SystemService.wifiConnecting)
            return;
        SystemService.connectWifi(ssid, wifiPassword.text);
    }

    function wifiDetailRows(details) {
        const rows = [
            { label: I18n.tr("securityType"),
                value: details.security || I18n.tr("openNetwork") },
            { label: I18n.tr("signalStrength"),
                value: details.strength !== undefined
                    ? details.strength + "%" : "" },
            { label: I18n.tr("networkBand"),
                value: SystemService.wifiBand(details.frequency) },
            { label: I18n.tr("networkChannel"), value: details.channel },
            { label: I18n.tr("linkSpeed"), value: details.rate },
            { label: I18n.tr("bssid"), value: details.bssid },
            { label: I18n.tr("networkAdapter"), value: details.device },
            { label: I18n.tr("ipv4Address"), value: details.ipv4Address },
            { label: I18n.tr("ipv4Gateway"), value: details.ipv4Gateway },
            { label: I18n.tr("dnsServers"), value: details.ipv4Dns },
            { label: I18n.tr("ipv6Address"), value: details.ipv6Address },
            { label: I18n.tr("macAddress"), value: details.macAddress },
            { label: I18n.tr("mtu"), value: details.mtu }
        ];
        return rows.filter(row => String(row.value ?? "").length > 0
            && row.value !== "—");
    }

    onActiveChanged: {
        if (active)
            BrightnessService.refresh();
    }
    onOutputNameChanged: {
        if (active)
            BrightnessService.refresh();
    }

    Connections {
        target: SystemService

        function onPasswordRequestedSsidChanged() {
            wifiPassword.clear();
            root.wifiPasswordVisible = false;
            if (SystemService.passwordRequestedSsid) {
                Qt.callLater(() => {
                    wifiPassword.forceActiveFocus();
                    scroll.contentY = Math.max(0,
                        scroll.contentHeight - scroll.height);
                });
            }
        }
    }

    implicitWidth: Appearance.px(650)
    implicitHeight: Appearance.px(680)

    component PanelText: AppText {
        color: panelPalette.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component ControlSlider: Controls.Slider {
        id: slider
        Layout.fillWidth: true
        implicitHeight: Appearance.px(30)
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: Appearance.px(8)
            radius: Appearance.fullRadius
            color: panelPalette.layer1Active
            border.width: 1
            border.color: panelPalette.outline
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: panelPalette.primary
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition
                * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Appearance.px(5)
            implicitHeight: Appearance.px(24)
            radius: Appearance.fullRadius
            color: panelPalette.primary
        }
    }

    component SummaryCard: Rectangle {
        id: card

        required property string icon
        required property string title
        property string subtitle: ""
        property bool active: false
        property bool expandable: false
        property bool expanded: false
        signal iconClicked
        signal bodyClicked

        Layout.fillWidth: true
        implicitHeight: Appearance.px(76)
        radius: Appearance.smallRadius
        color: bodyArea.containsMouse
            ? panelPalette.layer1Hover : panelPalette.layer3
        border.width: 1
        border.color: panelPalette.outline

        Rectangle {
            id: iconButton
            anchors {
                left: parent.left
                leftMargin: Appearance.px(9)
                verticalCenter: parent.verticalCenter
            }
            width: Appearance.px(52)
            height: Appearance.px(58)
            radius: Appearance.px(12)
            color: iconArea.containsMouse
                ? panelPalette.layer1Active
                : card.active
                    ? panelPalette.primaryContainer : panelPalette.layer1
            scale: iconArea.pressed ? 0.9 : 1

            AppText {
                anchors.centerIn: parent
                text: card.icon
                color: card.active
                    ? panelPalette.primaryContainerText : panelPalette.subtext
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(25)
                }
            }

            MouseArea {
                id: iconArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.iconClicked()
            }

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

        Column {
            anchors {
                left: iconButton.right
                right: expandIcon.visible ? expandIcon.left : parent.right
                leftMargin: Appearance.px(12)
                rightMargin: Appearance.px(10)
                verticalCenter: parent.verticalCenter
            }
            spacing: Appearance.px(2)

            PanelText {
                width: parent.width
                text: card.title
                elide: Text.ElideRight
                color: panelPalette.layer0Text
                font.pixelSize: Appearance.fontSize + Appearance.px(1)
            }
            PanelText {
                width: parent.width
                text: card.subtitle
                elide: Text.ElideRight
                color: panelPalette.subtext
                font.pixelSize: Appearance.smallFontSize
            }
        }

        AppText {
            id: expandIcon

            visible: card.expandable
            anchors {
                right: parent.right
                rightMargin: Appearance.px(12)
                verticalCenter: parent.verticalCenter
            }
            text: "󰅀"
            rotation: card.expanded ? 90 : 0
            color: panelPalette.subtext
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.px(15)
            }

            Behavior on rotation {
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: bodyArea
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: iconButton.right
                right: parent.right
            }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.bodyClicked()
        }
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: panelColumn.implicitHeight + Appearance.px(24)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: Controls.ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: panelColumn
            x: Appearance.px(root.embedded ? 18 : 16)
            y: Appearance.px(root.embedded ? 18 : 12)
            width: scroll.width - Appearance.px(root.embedded ? 36 : 32)
            spacing: Appearance.px(10)

            SettingsPageHeader {
                useBarPalette: root.useBarPalette
                visible: root.embedded
                icon: "󰒓"
                title: I18n.tr("networkDevices")
                onCloseClicked: root.closeRequested()
            }

            PopupHeader {
                useBarPalette: root.useBarPalette
                visible: !root.embedded
                icon: "󰒓"
                title: I18n.tr("networkDevices")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(10)

                AppText {
                    text: SystemService.volumeIcon()
                    color: panelPalette.layer1Text
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
                        pixelSize: Appearance.px(20)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.toggleMute()
                    }
                }
                ControlSlider {
                    from: 0
                    to: 1
                    value: SystemService.volume
                    onMoved: SystemService.setVolume(value)
                }
                PanelText {
                    Layout.preferredWidth: Appearance.px(44)
                    text: Math.round(SystemService.volume * 100) + "%"
                    color: panelPalette.subtext
                }

                AppText {
                    text: SystemService.microphoneIcon()
                    color: panelPalette.layer1Text
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
                        pixelSize: Appearance.px(20)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemService.toggleMicrophoneMute()
                    }
                }
                ControlSlider {
                    from: 0
                    to: 1
                    value: SystemService.microphoneVolume
                    onMoved: SystemService.setMicrophoneVolume(value)
                }
                PanelText {
                    Layout.preferredWidth: Appearance.px(44)
                    text: Math.round(SystemService.microphoneVolume * 100) + "%"
                    color: panelPalette.subtext
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(82)
                radius: Appearance.px(12)
                color: panelPalette.layer3
                border.width: 1
                border.color: panelPalette.outline

                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.px(12)
                        rightMargin: Appearance.px(12)
                        topMargin: Appearance.px(8)
                        bottomMargin: Appearance.px(7)
                    }
                    spacing: Appearance.px(2)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        AppText {
                            text: "󰃠"
                            color: root.brightnessState.available
                                ? panelPalette.primary : panelPalette.subtext
                            font {
                                family: Appearance.iconFontFamily
                                weight: Font.Normal
                                pixelSize: Appearance.px(21)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            PanelText {
                                Layout.fillWidth: true
                                text: I18n.tr("brightness") + " · "
                                    + (root.outputName || I18n.tr("unknown"))
                                color: panelPalette.layer0Text
                                elide: Text.ElideRight
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: root.brightnessState.error
                                    || root.brightnessState.reason
                                visible: text.length > 0
                                color: root.brightnessState.error
                                    ? panelPalette.error
                                    : panelPalette.subtext
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        PanelText {
                            Layout.preferredWidth: Appearance.px(44)
                            horizontalAlignment: Text.AlignRight
                            text: root.brightnessState.available
                                ? Math.round(root.brightnessState.percent) + "%"
                                : "—"
                            color: panelPalette.subtext
                        }
                    }

                    ControlSlider {
                        Layout.fillWidth: true
                        from: 1
                        to: 100
                        stepSize: 1
                        enabled: root.brightnessState.available
                        value: root.brightnessState.available
                            ? root.brightnessState.percent : 1
                        onMoved: BrightnessService.setBrightness(
                            root.outputName, value)
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Appearance.px(9)
                rowSpacing: Appearance.px(9)

                SummaryCard {
                    icon: SystemService.wifiEnabled
                        ? SystemService.wifiIcon() : "󰤭"
                    title: SystemService.wifiEnabled
                        ? (SystemService.activeWifiSsid
                            || I18n.tr("wifiEnabled"))
                        : I18n.tr("wifiDisabled")
                    subtitle: SystemService.activeWifiSsid
                        ? SystemService.wifiStrength + "%"
                        : I18n.tr("clickNetworks")
                    active: SystemService.wifiEnabled
                    expandable: true
                    expanded: root.expandedSection === "wifi"
                    onIconClicked: SystemService.toggleWifi()
                    onBodyClicked: {
                        root.expandedSection =
                            root.expandedSection === "wifi" ? "" : "wifi";
                        if (root.expandedSection === "wifi")
                            SystemService.refreshWifi(true);
                    }
                }

                SummaryCard {
                    icon: "󰂯"
                    title: SystemService.bluetoothEnabled
                        ? I18n.tr("bluetoothEnabled")
                        : I18n.tr("bluetoothDisabled")
                    subtitle: SystemService.connectedBluetoothName
                        || I18n.tr("clickDevices")
                    active: SystemService.bluetoothEnabled
                    expandable: true
                    expanded: root.expandedSection === "bluetooth"
                    onIconClicked: SystemService.toggleBluetooth()
                    onBodyClicked: {
                        root.expandedSection =
                            root.expandedSection === "bluetooth" ? "" : "bluetooth";
                        if (root.expandedSection === "bluetooth")
                            SystemService.setBluetoothDiscovering(true);
                    }
                }

                SummaryCard {
                    icon: SystemService.volumeIcon()
                    title: SystemService.sinkName
                    subtitle: SystemService.muted
                        ? I18n.tr("muted")
                        : Math.round(SystemService.volume * 100) + "%"
                    active: !SystemService.muted
                    expandable: true
                    expanded: root.expandedSection === "audioOutput"
                    onIconClicked: SystemService.toggleMute()
                    onBodyClicked: {
                        root.expandedSection =
                            root.expandedSection === "audioOutput"
                                ? "" : "audioOutput";
                    }
                }

                SummaryCard {
                    icon: SystemService.microphoneIcon()
                    title: SystemService.sourceName
                    subtitle: SystemService.microphoneMuted
                        ? I18n.tr("microphoneDisabled")
                        : Math.round(SystemService.microphoneVolume * 100) + "%"
                    active: !SystemService.microphoneMuted
                    expandable: true
                    expanded: root.expandedSection === "audioInput"
                    onIconClicked: SystemService.toggleMicrophoneMute()
                    onBodyClicked: {
                        root.expandedSection =
                            root.expandedSection === "audioInput"
                                ? "" : "audioInput";
                    }
                }
            }

            Rectangle {
                visible: root.expandedSection === "wifi"
                Layout.fillWidth: true
                implicitHeight: wifiColumn.implicitHeight + Appearance.px(20)
                radius: Appearance.smallRadius
                color: panelPalette.layer1

                ColumnLayout {
                    id: wifiColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Appearance.px(10)
                    }
                    spacing: Appearance.px(7)

                    RowLayout {
                        Layout.fillWidth: true
                        PanelText {
                            Layout.fillWidth: true
                            text: I18n.tr("wifiNetworks")
                            color: panelPalette.layer0Text
                            font.weight: Font.DemiBold
                        }
                        PanelText {
                            text: SystemService.wifiScanning
                                ? I18n.tr("scanning") : "󰑐"
                            color: panelPalette.primary
                            MouseArea {
                                anchors.fill: parent
                                onClicked: SystemService.refreshWifi(true)
                            }
                        }
                    }

                    Repeater {
                        model: SystemService.wifiNetworks.slice(0, 8)
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: Appearance.px(54)
                            radius: Appearance.px(10)
                            color: wifiMouse.containsMouse
                                ? panelPalette.layer1Hover : panelPalette.layer2
                            border.width: modelData.active ? 2
                                : SystemService.wifiDetailsSsid
                                    === modelData.ssid ? 1 : 0
                            border.color: panelPalette.primary
                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                AppText {
                                    text: SystemService.wifiIcon(modelData.strength)
                                    color: panelPalette.primary
                                    font {
                                        family: Appearance.iconFontFamily
                                        weight: Font.Normal
                                        pixelSize: Appearance.px(18)
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    PanelText {
                                        Layout.fillWidth: true
                                        text: modelData.ssid
                                        elide: Text.ElideRight
                                        color: panelPalette.layer0Text
                                    }
                                    PanelText {
                                        text: (modelData.active
                                                ? I18n.tr("connected") + " · " : "")
                                            + (modelData.secure
                                                ? I18n.tr("secure") + " · " : "")
                                            + modelData.strength + "%"
                                        color: panelPalette.subtext
                                        font.pixelSize: Appearance.smallFontSize
                                    }
                                }

                                Rectangle {
                                    id: wifiDetailsButton

                                    Layout.preferredWidth: Appearance.px(34)
                                    Layout.preferredHeight: Appearance.px(34)
                                    radius: Appearance.fullRadius
                                    color: SystemService.wifiDetailsSsid
                                            === modelData.ssid
                                        ? panelPalette.primaryContainer
                                        : wifiDetailsMouse.containsMouse
                                            ? panelPalette.layer1Active
                                            : "transparent"

                                    AppText {
                                        anchors.centerIn: parent
                                        text: "󰋼"
                                        color: SystemService.wifiDetailsSsid
                                                === modelData.ssid
                                            ? panelPalette.primaryContainerText
                                            : panelPalette.subtext
                                        font {
                                            family: Appearance.iconFontFamily
                                            weight: Font.Normal
                                            pixelSize: Appearance.px(17)
                                        }
                                    }

                                    MouseArea {
                                        id: wifiDetailsMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: SystemService.toggleWifiDetails(
                                            modelData.ssid)
                                    }
                                }
                            }
                            MouseArea {
                                id: wifiMouse
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: parent.right
                                    rightMargin: Appearance.px(54)
                                }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.connectWifi(modelData.ssid)
                            }
                        }
                    }

                    Rectangle {
                        visible: SystemService.wifiDetailsSsid !== ""
                        Layout.fillWidth: true
                        implicitHeight: wifiDetailsColumn.implicitHeight
                            + Appearance.px(20)
                        radius: Appearance.px(12)
                        color: panelPalette.layer2
                        border.width: 1
                        border.color: panelPalette.outline

                        ColumnLayout {
                            id: wifiDetailsColumn

                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: Appearance.px(10)
                            }
                            spacing: Appearance.px(9)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.px(9)

                                Rectangle {
                                    Layout.preferredWidth: Appearance.px(38)
                                    Layout.preferredHeight: Appearance.px(38)
                                    radius: Appearance.fullRadius
                                    color: panelPalette.primaryContainer

                                    AppText {
                                        anchors.centerIn: parent
                                        text: SystemService.wifiIcon(
                                            SystemService.wifiDetails.strength)
                                        color: panelPalette.primaryContainerText
                                        font {
                                            family: Appearance.iconFontFamily
                                            weight: Font.Normal
                                            pixelSize: Appearance.px(19)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: SystemService.wifiDetailsSsid
                                        color: panelPalette.layer0Text
                                        elide: Text.ElideRight
                                        font.weight: Font.DemiBold
                                    }

                                    PanelText {
                                        text: SystemService.wifiDetails.active
                                            ? I18n.tr("connected") + " · "
                                                + I18n.tr("networkDetails")
                                            : I18n.tr("networkDetails")
                                        color: SystemService.wifiDetails.active
                                            ? panelPalette.primary
                                            : panelPalette.subtext
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }
                                }

                                PanelText {
                                    visible: SystemService.wifiDetailsLoading
                                    text: I18n.tr("loading") + "…"
                                    color: panelPalette.subtext
                                    font.pixelSize: Appearance.smallFontSize
                                }

                                Rectangle {
                                    Layout.preferredWidth: Appearance.px(32)
                                    Layout.preferredHeight: Appearance.px(32)
                                    radius: Appearance.fullRadius
                                    color: closeWifiDetailsMouse.containsMouse
                                        ? panelPalette.layer1Active
                                        : "transparent"

                                    AppText {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: panelPalette.subtext
                                        font {
                                            family: Appearance.iconFontFamily
                                            weight: Font.Normal
                                            pixelSize: Appearance.px(16)
                                        }
                                    }

                                    MouseArea {
                                        id: closeWifiDetailsMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: SystemService.hideWifiDetails()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: panelPalette.outline
                                opacity: 0.7
                            }

                            GridLayout {
                                id: wifiDetailsGrid

                                Layout.fillWidth: true
                                columns: 2
                                uniformCellWidths: true
                                columnSpacing: Appearance.px(16)
                                rowSpacing: Appearance.px(9)

                                Repeater {
                                    model: root.wifiDetailRows(
                                        SystemService.wifiDetails)

                                    delegate: ColumnLayout {
                                        id: wifiDetailField

                                        required property var modelData

                                        Layout.fillWidth: true
                                        spacing: Appearance.px(1)

                                        PanelText {
                                            Layout.fillWidth: true
                                            text: wifiDetailField.modelData.label
                                            color: panelPalette.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }

                                        PanelText {
                                            Layout.fillWidth: true
                                            text: wifiDetailField.modelData.value
                                            color: panelPalette.layer0Text
                                            wrapMode: Text.WrapAnywhere
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: SystemService.passwordRequestedSsid !== ""
                        Layout.fillWidth: true
                        implicitHeight: wifiPasswordColumn.implicitHeight
                            + Appearance.px(20)
                        radius: Appearance.px(12)
                        color: panelPalette.layer2
                        border.width: 1
                        border.color: wifiPassword.activeFocus
                            ? panelPalette.primary : panelPalette.outline

                        ColumnLayout {
                            id: wifiPasswordColumn

                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: Appearance.px(10)
                            }
                            spacing: Appearance.px(9)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.px(9)

                                AppText {
                                    text: "󰌾"
                                    color: panelPalette.primary
                                    font {
                                        family: Appearance.iconFontFamily
                                        weight: Font.Normal
                                        pixelSize: Appearance.px(19)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: I18n.tr("wifiPassword")
                                        color: panelPalette.layer0Text
                                        font.weight: Font.DemiBold
                                    }

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: SystemService.passwordRequestedSsid
                                        color: panelPalette.subtext
                                        elide: Text.ElideRight
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: Appearance.px(32)
                                    Layout.preferredHeight: Appearance.px(32)
                                    radius: Appearance.fullRadius
                                    color: cancelWifiMouse.containsMouse
                                        ? panelPalette.layer1Active
                                        : "transparent"

                                    AppText {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: panelPalette.subtext
                                        font {
                                            family: Appearance.iconFontFamily
                                            weight: Font.Normal
                                            pixelSize: Appearance.px(16)
                                        }
                                    }

                                    MouseArea {
                                        id: cancelWifiMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked:
                                            SystemService.cancelWifiPassword()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.px(8)

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: Appearance.px(40)
                                    radius: Appearance.px(10)
                                    color: panelPalette.layer1
                                    border.width: wifiPassword.activeFocus
                                        ? 1 : 0
                                    border.color: panelPalette.primary

                                    AppTextField {
                                        id: wifiPassword

                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                            left: parent.left
                                            right: showWifiPasswordButton.left
                                            leftMargin: Appearance.px(10)
                                        }
                                        padding: 0
                                        color: panelPalette.layer0Text
                                        placeholderText:
                                            I18n.tr("wifiPasswordHint")
                                        placeholderTextColor:
                                            panelPalette.subtext
                                        selectionColor:
                                            panelPalette.primaryContainer
                                        selectedTextColor:
                                            panelPalette.primaryContainerText
                                        selectByMouse: true
                                        echoMode: root.wifiPasswordVisible
                                            ? TextInput.Normal
                                            : TextInput.Password
                                        inputMethodHints: Qt.ImhSensitiveData
                                            | Qt.ImhNoPredictiveText
                                        verticalAlignment:
                                            TextInput.AlignVCenter
                                        background: null
                                        enabled: !SystemService.wifiConnecting
                                        font {
                                            family: Appearance.fontFamily
                                            pixelSize: Appearance.fontSize
                                        }
                                        onAccepted: root.submitWifiPassword()
                                    }

                                    Rectangle {
                                        id: showWifiPasswordButton

                                        anchors {
                                            right: parent.right
                                            rightMargin: Appearance.px(4)
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width: Appearance.px(32)
                                        height: Appearance.px(32)
                                        radius: Appearance.fullRadius
                                        color: showWifiPasswordMouse.containsMouse
                                            ? panelPalette.layer1Active
                                            : "transparent"

                                        AppText {
                                            anchors.centerIn: parent
                                            text: root.wifiPasswordVisible
                                                ? "󰈈" : "󰈉"
                                            color: panelPalette.subtext
                                            font {
                                                family:
                                                    Appearance.iconFontFamily
                                                weight: Font.Normal
                                                pixelSize: Appearance.px(17)
                                            }
                                        }

                                        MouseArea {
                                            id: showWifiPasswordMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.wifiPasswordVisible =
                                                    !root.wifiPasswordVisible;
                                                wifiPassword.forceActiveFocus();
                                            }
                                        }

                                        StyledToolTip {
                                            visible:
                                                showWifiPasswordMouse
                                                    .containsMouse
                                            text: root.wifiPasswordVisible
                                                ? I18n.tr("hidePassword")
                                                : I18n.tr("showPassword")
                                        }
                                    }
                                }

                                Rectangle {
                                    readonly property bool canConnect:
                                        wifiPassword.text.length > 0
                                            && !SystemService.wifiConnecting

                                    Layout.preferredWidth: Appearance.px(88)
                                    implicitHeight: Appearance.px(40)
                                    radius: Appearance.px(10)
                                    color: canConnect
                                        ? panelPalette.primaryContainer
                                        : panelPalette.layer1Active
                                    opacity: canConnect ? 1 : 0.65

                                    PanelText {
                                        anchors.centerIn: parent
                                        text: SystemService.wifiConnecting
                                            ? I18n.tr("loading") + "…"
                                            : I18n.tr("connect")
                                        color: parent.canConnect
                                            ? panelPalette.primaryContainerText
                                            : panelPalette.subtext
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: parent.canConnect
                                        hoverEnabled: enabled
                                        cursorShape: enabled
                                            ? Qt.PointingHandCursor
                                            : Qt.ArrowCursor
                                        onClicked: root.submitWifiPassword()
                                    }
                                }
                            }

                            PanelText {
                                visible: SystemService.statusMessage !== ""
                                Layout.fillWidth: true
                                text: SystemService.statusMessage
                                color: panelPalette.error
                                wrapMode: Text.WordWrap
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.expandedSection === "bluetooth"
                Layout.fillWidth: true
                implicitHeight: bluetoothColumn.implicitHeight + Appearance.px(20)
                radius: Appearance.smallRadius
                color: panelPalette.layer1

                ColumnLayout {
                    id: bluetoothColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Appearance.px(10)
                    }
                    spacing: Appearance.px(7)

                    RowLayout {
                        Layout.fillWidth: true
                        PanelText {
                            Layout.fillWidth: true
                            text: I18n.tr("bluetoothDevices")
                            color: panelPalette.layer0Text
                            font.weight: Font.DemiBold
                        }
                        PanelText {
                            text: SystemService.bluetoothDiscovering
                                ? I18n.tr("scanning") : I18n.tr("scan")
                            color: panelPalette.primary
                            MouseArea {
                                anchors.fill: parent
                                onClicked: SystemService.setBluetoothDiscovering(true)
                            }
                        }
                    }

                    Repeater {
                        model: SystemService.bluetoothDevices.slice(0, 8)
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: Appearance.px(52)
                            radius: Appearance.px(10)
                            color: bluetoothMouse.containsMouse
                                ? panelPalette.layer1Hover : panelPalette.layer2
                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                AppText {
                                    text: "󰂯"
                                    color: modelData.connected
                                        ? panelPalette.primary : panelPalette.subtext
                                    font {
                                        family: Appearance.iconFontFamily
                                        weight: Font.Normal
                                        pixelSize: Appearance.px(18)
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    PanelText {
                                        Layout.fillWidth: true
                                        text: modelData.name || modelData.deviceName
                                        elide: Text.ElideRight
                                        color: panelPalette.layer0Text
                                    }
                                    PanelText {
                                        text: modelData.connected
                                            ? I18n.tr("connected")
                                            : modelData.pairing
                                                ? I18n.tr("pairing")
                                                : modelData.paired
                                                    ? I18n.tr("paired")
                                                    : I18n.tr("availableToConnect")
                                        color: panelPalette.subtext
                                        font.pixelSize: Appearance.smallFontSize
                                    }
                                }
                                PanelText {
                                    text: modelData.connected
                                        ? I18n.tr("disconnect") : I18n.tr("connect")
                                    color: panelPalette.primary
                                }
                            }
                            MouseArea {
                                id: bluetoothMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.toggleBluetoothDevice(modelData)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.expandedSection === "audioOutput"
                Layout.fillWidth: true
                implicitHeight: outputColumn.implicitHeight
                    + Appearance.px(20)
                radius: Appearance.smallRadius
                color: panelPalette.layer1

                ColumnLayout {
                    id: outputColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Appearance.px(10)
                    }
                    spacing: Appearance.px(7)

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("audioOutputs")
                        color: panelPalette.layer0Text
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        visible: SystemService.outputDevices.length === 0
                        Layout.fillWidth: true
                        text: I18n.tr("noAudioDevices")
                        color: panelPalette.subtext
                    }

                    Repeater {
                        model: SystemService.outputDevices

                        delegate: Rectangle {
                            required property var modelData

                            readonly property bool selected:
                                modelData === SystemService.sink

                            Layout.fillWidth: true
                            implicitHeight: Appearance.px(52)
                            radius: Appearance.px(10)
                            color: outputMouse.containsMouse
                                ? panelPalette.layer1Hover : panelPalette.layer2
                            border.width: selected ? 2 : 0
                            border.color: panelPalette.primary

                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                spacing: Appearance.px(9)

                                AppText {
                                    text: "󰕾"
                                    color: parent.parent.selected
                                        ? panelPalette.primary
                                        : panelPalette.subtext
                                    font {
                                        family: Appearance.iconFontFamily
                                        weight: Font.Normal
                                        pixelSize: Appearance.px(18)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: SystemService.audioDeviceName(
                                            modelData)
                                        elide: Text.ElideRight
                                        color: panelPalette.layer0Text
                                    }

                                    PanelText {
                                        visible: parent.parent.parent.selected
                                        text: I18n.tr("currentDevice")
                                        color: panelPalette.primary
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }
                                }

                                PanelText {
                                    visible: parent.parent.selected
                                    text: "󰄬"
                                    color: panelPalette.primary
                                    font.family:
                                        Appearance.iconFontFamily
                                }
                            }

                            MouseArea {
                                id: outputMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SystemService.setDefaultOutput(modelData);
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.expandedSection === "audioInput"
                Layout.fillWidth: true
                implicitHeight: inputColumn.implicitHeight
                    + Appearance.px(20)
                radius: Appearance.smallRadius
                color: panelPalette.layer1

                ColumnLayout {
                    id: inputColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Appearance.px(10)
                    }
                    spacing: Appearance.px(7)

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("audioInputs")
                        color: panelPalette.layer0Text
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        visible: SystemService.inputDevices.length === 0
                        Layout.fillWidth: true
                        text: I18n.tr("noAudioDevices")
                        color: panelPalette.subtext
                    }

                    Repeater {
                        model: SystemService.inputDevices

                        delegate: Rectangle {
                            required property var modelData

                            readonly property bool selected:
                                modelData === SystemService.source

                            Layout.fillWidth: true
                            implicitHeight: Appearance.px(52)
                            radius: Appearance.px(10)
                            color: inputMouse.containsMouse
                                ? panelPalette.layer1Hover : panelPalette.layer2
                            border.width: selected ? 2 : 0
                            border.color: panelPalette.primary

                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                spacing: Appearance.px(9)

                                AppText {
                                    text: "󰍬"
                                    color: parent.parent.selected
                                        ? panelPalette.primary
                                        : panelPalette.subtext
                                    font {
                                        family: Appearance.iconFontFamily
                                        weight: Font.Normal
                                        pixelSize: Appearance.px(18)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: SystemService.audioDeviceName(
                                            modelData)
                                        elide: Text.ElideRight
                                        color: panelPalette.layer0Text
                                    }

                                    PanelText {
                                        visible: parent.parent.parent.selected
                                        text: I18n.tr("currentDevice")
                                        color: panelPalette.primary
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }
                                }

                                PanelText {
                                    visible: parent.parent.selected
                                    text: "󰄬"
                                    color: panelPalette.primary
                                    font.family:
                                        Appearance.iconFontFamily
                                }
                            }

                            MouseArea {
                                id: inputMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SystemService.setDefaultInput(modelData);
                                }
                            }
                        }
                    }
                }
            }

            PanelText {
                visible: SystemService.statusMessage !== ""
                    && SystemService.passwordRequestedSsid === ""
                Layout.fillWidth: true
                text: SystemService.statusMessage
                color: panelPalette.error
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.smallFontSize
            }
        }
    }
}
