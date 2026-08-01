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
    property string expandedSection: embedded ? "wifi" : ""
    signal closeRequested

    implicitWidth: Appearance.px(650)
    implicitHeight: Appearance.px(680)

    component PanelText: Text {
        color: Appearance.layer1Text
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
            height: Appearance.px(7)
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
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Appearance.px(5)
            implicitHeight: Appearance.px(24)
            radius: Appearance.fullRadius
            color: Appearance.primary
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
            ? Appearance.layer1Hover : Appearance.layer3
        border.width: 1
        border.color: Appearance.outline

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
                ? Appearance.layer1Active
                : card.active
                    ? Appearance.primaryContainer : Appearance.layer1
            scale: iconArea.pressed ? 0.9 : 1

            Text {
                anchors.centerIn: parent
                text: card.icon
                color: card.active
                    ? Appearance.primaryContainerText : Appearance.subtext
                font {
                    family: Appearance.iconFontFamily
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
                color: Appearance.layer0Text
                font.pixelSize: Appearance.fontSize + Appearance.px(1)
            }
            PanelText {
                width: parent.width
                text: card.subtitle
                elide: Text.ElideRight
                color: Appearance.subtext
                font.pixelSize: Appearance.smallFontSize
            }
        }

        Text {
            id: expandIcon

            visible: card.expandable
            anchors {
                right: parent.right
                rightMargin: Appearance.px(12)
                verticalCenter: parent.verticalCenter
            }
            text: "󰅀"
            rotation: card.expanded ? 90 : 0
            color: Appearance.subtext
            font {
                family: Appearance.iconFontFamily
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
            x: Appearance.px(16)
            y: Appearance.px(12)
            width: scroll.width - Appearance.px(32)
            spacing: Appearance.px(10)

            PopupHeader {
                icon: "󰒓"
                title: I18n.tr("networkDevices")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(10)

                Text {
                    text: SystemService.volumeIcon()
                    color: Appearance.layer1Text
                    font {
                        family: Appearance.iconFontFamily
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
                    color: Appearance.subtext
                }

                Text {
                    text: SystemService.microphoneIcon()
                    color: Appearance.layer1Text
                    font {
                        family: Appearance.iconFontFamily
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
                    color: Appearance.subtext
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
                color: Appearance.layer1

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
                            color: Appearance.layer0Text
                            font.weight: Font.DemiBold
                        }
                        PanelText {
                            text: SystemService.wifiScanning
                                ? I18n.tr("scanning") : "󰑐"
                            color: Appearance.primary
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
                                ? Appearance.layer1Hover : Appearance.layer2
                            border.width: modelData.active ? 2 : 0
                            border.color: Appearance.primary
                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                Text {
                                    text: SystemService.wifiIcon(modelData.strength)
                                    color: Appearance.primary
                                    font {
                                        family: Appearance.iconFontFamily
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
                                        color: Appearance.layer0Text
                                    }
                                    PanelText {
                                        text: (modelData.active
                                                ? I18n.tr("connected") + " · " : "")
                                            + (modelData.secure
                                                ? I18n.tr("secure") + " · " : "")
                                            + modelData.strength + "%"
                                        color: Appearance.subtext
                                        font.pixelSize: Appearance.smallFontSize
                                    }
                                }
                            }
                            MouseArea {
                                id: wifiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.connectWifi(modelData.ssid)
                            }
                        }
                    }

                    RowLayout {
                        visible: SystemService.passwordRequestedSsid !== ""
                        Layout.fillWidth: true
                        PanelText {
                            text: SystemService.passwordRequestedSsid
                            color: Appearance.layer0Text
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Appearance.px(34)
                            radius: Appearance.px(9)
                            color: Appearance.layer2
                            TextInput {
                                id: wifiPassword
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(8)
                                }
                                color: Appearance.layer0Text
                                echoMode: TextInput.Password
                                verticalAlignment: TextInput.AlignVCenter
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                }
                            }
                        }
                        Rectangle {
                            implicitWidth: Appearance.px(72)
                            implicitHeight: Appearance.px(34)
                            radius: Appearance.px(9)
                            color: Appearance.primaryContainer
                            PanelText {
                                anchors.centerIn: parent
                                text: I18n.tr("connect")
                                color: Appearance.primaryContainerText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    SystemService.connectWifi(
                                        SystemService.passwordRequestedSsid,
                                        wifiPassword.text);
                                    wifiPassword.text = "";
                                }
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
                color: Appearance.layer1

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
                            color: Appearance.layer0Text
                            font.weight: Font.DemiBold
                        }
                        PanelText {
                            text: SystemService.bluetoothDiscovering
                                ? I18n.tr("scanning") : I18n.tr("scan")
                            color: Appearance.primary
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
                                ? Appearance.layer1Hover : Appearance.layer2
                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                Text {
                                    text: "󰂯"
                                    color: modelData.connected
                                        ? Appearance.primary : Appearance.subtext
                                    font {
                                        family: Appearance.iconFontFamily
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
                                        color: Appearance.layer0Text
                                    }
                                    PanelText {
                                        text: modelData.connected
                                            ? I18n.tr("connected")
                                            : modelData.pairing
                                                ? I18n.tr("pairing")
                                                : modelData.paired
                                                    ? I18n.tr("paired")
                                                    : I18n.tr("availableToConnect")
                                        color: Appearance.subtext
                                        font.pixelSize: Appearance.smallFontSize
                                    }
                                }
                                PanelText {
                                    text: modelData.connected
                                        ? I18n.tr("disconnect") : I18n.tr("connect")
                                    color: Appearance.primary
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
                color: Appearance.layer1

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
                        color: Appearance.layer0Text
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        visible: SystemService.outputDevices.length === 0
                        Layout.fillWidth: true
                        text: I18n.tr("noAudioDevices")
                        color: Appearance.subtext
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
                                ? Appearance.layer1Hover : Appearance.layer2
                            border.width: selected ? 2 : 0
                            border.color: Appearance.primary

                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                spacing: Appearance.px(9)

                                Text {
                                    text: "󰕾"
                                    color: parent.parent.selected
                                        ? Appearance.primary
                                        : Appearance.subtext
                                    font {
                                        family: Appearance.iconFontFamily
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
                                        color: Appearance.layer0Text
                                    }

                                    PanelText {
                                        visible: parent.parent.parent.selected
                                        text: I18n.tr("currentDevice")
                                        color: Appearance.primary
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }
                                }

                                PanelText {
                                    visible: parent.parent.selected
                                    text: "󰄬"
                                    color: Appearance.primary
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
                color: Appearance.layer1

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
                        color: Appearance.layer0Text
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        visible: SystemService.inputDevices.length === 0
                        Layout.fillWidth: true
                        text: I18n.tr("noAudioDevices")
                        color: Appearance.subtext
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
                                ? Appearance.layer1Hover : Appearance.layer2
                            border.width: selected ? 2 : 0
                            border.color: Appearance.primary

                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(10)
                                }
                                spacing: Appearance.px(9)

                                Text {
                                    text: "󰍬"
                                    color: parent.parent.selected
                                        ? Appearance.primary
                                        : Appearance.subtext
                                    font {
                                        family: Appearance.iconFontFamily
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
                                        color: Appearance.layer0Text
                                    }

                                    PanelText {
                                        visible: parent.parent.parent.selected
                                        text: I18n.tr("currentDevice")
                                        color: Appearance.primary
                                        font.pixelSize:
                                            Appearance.smallFontSize
                                    }
                                }

                                PanelText {
                                    visible: parent.parent.selected
                                    text: "󰄬"
                                    color: Appearance.primary
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
                Layout.fillWidth: true
                text: SystemService.statusMessage
                color: Theme.palette.m3error
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.smallFontSize
            }
        }
    }
}
