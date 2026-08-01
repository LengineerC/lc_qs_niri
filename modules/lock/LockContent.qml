pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    property var context: null
    property date now: new Date()

    readonly property real sideWidth:
        Math.max(Appearance.px(240), width * 0.265)
    readonly property real centerWidth:
        Math.max(Appearance.px(330), width * 0.36)
    readonly property int cardSpacing: Appearance.px(12)

    function forceAuthFocus() {
        passwordInput.forceActiveFocus();
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.px(22)

        ColumnLayout {
            Layout.preferredWidth: root.sideWidth
            Layout.fillHeight: true
            spacing: root.cardSpacing

            LockCard {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height * 0.33
                topLeftRadius: Appearance.px(30)

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Appearance.px(14)
                    }
                    spacing: Appearance.px(6)

                    Text {
                        Layout.fillWidth: true
                        text: I18n.tr("weather")
                        color: Appearance.primary
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.px(25)
                            weight: Font.Bold
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Appearance.px(55)
                        spacing: Appearance.px(10)

                        Text {
                            Layout.preferredWidth: Appearance.px(58)
                            text: WeatherService.currentIcon
                            color: Appearance.primary
                            horizontalAlignment: Text.AlignHCenter
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(48)
                                weight: Font.Bold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.px(2)

                            Text {
                                Layout.fillWidth: true
                                text: WeatherService.ready
                                    ? WeatherService.description(
                                        WeatherService.current
                                            .weatherCode)
                                    : I18n.tr("weatherUnavailable")
                                color: Appearance.layer0Text
                                elide: Text.ElideRight
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.px(18)
                                    weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("humidity") + ": "
                                    + (WeatherService.ready
                                        ? WeatherService.formatPercent(
                                            WeatherService.current
                                                .humidity)
                                        : "--%")
                                color: Appearance.subtext
                                elide: Text.ElideRight
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.smallFontSize
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: Appearance.px(68)
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: WeatherService.currentTemperature
                                color: Appearance.primary
                                horizontalAlignment: Text.AlignRight
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.px(26)
                                    weight: Font.Medium
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("feelsLike") + ": "
                                    + (WeatherService.ready
                                        ? WeatherService
                                            .formatTemperature(
                                                WeatherService.current
                                                    .apparentTemperature)
                                        : "--°C")
                                color: Appearance.subtext
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.smallFontSize
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Appearance.px(40)

                        Repeater {
                            model: WeatherService.hourlyForecast

                            delegate: ColumnLayout {
                                id: forecastItem

                                required property var modelData

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 1
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: WeatherService.timeFromIso(
                                        forecastItem.modelData.time)
                                    color: Appearance.subtext
                                    horizontalAlignment: Text.AlignHCenter
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.px(15)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: WeatherService.icon(
                                        forecastItem.modelData.weatherCode,
                                        forecastItem.modelData.isDay)
                                    color: Appearance.layer0Text
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font {
                                        family: Appearance.iconFontFamily
                                        pixelSize: Appearance.px(40)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: WeatherService.formatTemperature(
                                        forecastItem.modelData.temperature)
                                    color: Appearance.layer1Text
                                    horizontalAlignment: Text.AlignHCenter
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.px(15)
                                        weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }
            }

            LockFastfetchCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                fontScale: 1.35
                iconScale: 1.4
                contentPadding: Appearance.px(10)
                sectionSpacing: -Appearance.px(3)
                rowSpacing: Appearance.px(7)
            }

            LockMediaCard {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height * 0.3
                bottomLeftRadius: Appearance.px(30)
            }
        }

        ColumnLayout {
            Layout.preferredWidth: root.centerWidth
            Layout.fillHeight: true
            spacing: Appearance.px(10)

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.px(5)

                Text {
                    text: I18n.locale.toString(
                        root.now, "HH")
                    color: Appearance.layer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Math.min(
                            Appearance.px(88),
                            root.height * 0.13)
                        weight: Font.Bold
                    }
                }

                Text {
                    text: ":"
                    color: Appearance.primary
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Math.min(
                            Appearance.px(88),
                            root.height * 0.13)
                        weight: Font.Bold
                    }
                }

                Text {
                    text: I18n.locale.toString(
                        root.now, "mm")
                    color: Appearance.layer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Math.min(
                            Appearance.px(88),
                            root.height * 0.13)
                        weight: Font.Bold
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.locale.toString(
                    root.now, "dddd, MMMM d")
                color: Appearance.tertiary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(21)
                    weight: Font.DemiBold
                }
            }

            UserAvatar {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.px(100)
                implicitSize: Math.min(
                    Appearance.px(150),
                    root.height * 0.22)
                imageInset: Appearance.px(3)
            }

            Text {
                Layout.fillWidth: true
                text: UserService.displayName
                color: Appearance.layer0Text
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.largeFontSize
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                id: authCard

                Layout.fillWidth: true
                Layout.topMargin: Appearance.px(40)
                Layout.leftMargin: Appearance.px(18)
                Layout.rightMargin: Appearance.px(18)
                implicitHeight: Appearance.px(58)
                radius: Appearance.fullRadius
                color: passwordInput.activeFocus
                    ? Appearance.layer3 : Appearance.layer2
                border.width: passwordInput.activeFocus ? 2 : 1
                border.color: root.context?.showFailure
                    ? Theme.palette.m3error
                    : passwordInput.activeFocus
                        ? Appearance.primary
                        : Appearance.outline

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.px(18)
                        rightMargin: Appearance.px(7)
                    }
                    spacing: Appearance.px(10)

                    Text {
                        id: authStateIcon

                        text: root.context?.unlockInProgress
                            ? "󰔟" : "󰌾"
                        color: root.context?.showFailure
                            ? Theme.palette.m3error
                            : Appearance.primary
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(18)
                        }

                        RotationAnimation on rotation {
                            running: root.context
                                ?.unlockInProgress ?? false
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                            onStopped: authStateIcon.rotation = 0
                        }
                    }

                    TextInput {
                        id: passwordInput

                        Layout.fillWidth: true
                        color: Appearance.layer0Text
                        selectionColor: Appearance.primary
                        selectedTextColor:
                            Theme.palette.m3onPrimary
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        passwordMaskDelay: 0
                        clip: true
                        enabled: !(root.context
                            ?.unlockInProgress ?? false)
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.fontSize
                            letterSpacing: Appearance.px(4)
                        }

                        onTextChanged: {
                            if (root.context
                                    && root.context.currentText
                                        !== text)
                                root.context.currentText = text;
                        }
                        onAccepted: {
                            if (root.context)
                                root.context.tryUnlock();
                        }

                        Text {
                            anchors {
                                fill: parent
                                verticalCenter: parent.verticalCenter
                            }
                            visible: !passwordInput.text
                            text: I18n.tr("enterPassword")
                            color: Appearance.subtext
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            font {
                                family: Appearance.fontFamily
                                pixelSize: Appearance.fontSize
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: Appearance.px(43)
                        implicitHeight: Appearance.px(43)
                        radius: Appearance.fullRadius
                        color: unlockArea.containsMouse
                            ? Appearance.primary
                            : Appearance.primaryContainer
                        scale: unlockArea.pressed ? 0.92 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰌑"
                            color: unlockArea.containsMouse
                                ? Theme.palette.m3onPrimary
                                : Appearance.primaryContainerText
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(18)
                            }
                        }

                        MouseArea {
                            id: unlockArea
                            anchors.fill: parent
                            enabled: passwordInput.text.length > 0
                                && !(root.context
                                    ?.unlockInProgress ?? false)
                            hoverEnabled: true
                            cursorShape: enabled
                                ? Qt.PointingHandCursor
                                : Qt.ArrowCursor
                            onClicked: root.context.tryUnlock()
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Appearance.fastDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: passwordInput.forceActiveFocus()
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.fastDuration
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.px(20)
                Layout.rightMargin: Appearance.px(20)
                Layout.preferredHeight: Appearance.px(22)
                text: root.context?.unlockInProgress
                    ? I18n.tr("authenticating")
                    : root.context?.showFailure
                        ? I18n.tr("incorrectPassword")
                        : ""
                color: root.context?.showFailure
                    ? Theme.palette.m3error
                    : Appearance.subtext
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.tr("unlockHint")
                color: Appearance.subtext
                opacity: 0.72
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }

            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            Layout.preferredWidth: root.sideWidth
            Layout.fillHeight: true
            spacing: root.cardSpacing

            LockNotificationCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                topRightRadius: Appearance.px(30)
            }

            LockCard {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height * 0.38
                bottomRightRadius: Appearance.px(30)

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Appearance.px(16)
                    }
                    spacing: Appearance.px(15)

                    Text {
                        Layout.fillWidth: true
                        text: I18n.tr("systemResources")
                        color: Appearance.layer0Text
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.largeFontSize
                            weight: Font.DemiBold
                        }
                    }

                    ResourceGauge {
                        Layout.fillWidth: true
                        icon: "󰻠"
                        label: I18n.tr("cpuUsage")
                        value: ResourceService.cpuUsage
                        valueText: Math.round(
                            ResourceService.cpuUsage * 100) + "%"
                    }

                    ResourceGauge {
                        Layout.fillWidth: true
                        icon: "󰍛"
                        label: I18n.tr("memoryUsage")
                        value: ResourceService.memoryUsage
                        valueText: Math.round(
                            ResourceService.memoryUsage * 100) + "%"
                    }

                    ResourceGauge {
                        Layout.fillWidth: true
                        icon: "󰔏"
                        label: I18n.tr("cpuTemperature")
                        value: ResourceService.temperatureAvailable
                            ? Math.min(1,
                                ResourceService.cpuTemperature / 100)
                            : 0
                        valueText:
                            ResourceService.temperatureAvailable
                                ? Math.round(
                                    ResourceService.cpuTemperature)
                                    + "°C"
                                : "--°C"
                    }

                    ResourceGauge {
                        readonly property var filesystem:
                            ResourceService.selectedFilesystem

                        Layout.fillWidth: true
                        icon: "󰋊"
                        label: I18n.tr("disk")
                            + (filesystem?.target
                                ? " · " + filesystem.target : "")
                        value: filesystem?.usage ?? 0
                        valueText: filesystem
                            ? Math.round(filesystem.usage * 100) + "%"
                            : "--%"
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(8)

                        NetworkRate {
                            Layout.fillWidth: true
                            icon: "󰁅"
                            label: I18n.tr("download")
                            value: ResourceService.formatRate(
                                ResourceService.downloadBytesPerSecond)
                        }

                        NetworkRate {
                            Layout.fillWidth: true
                            icon: "󰁝"
                            label: I18n.tr("upload")
                            value: ResourceService.formatRate(
                                ResourceService.uploadBytesPerSecond)
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: root.context
        ignoreUnknownSignals: true

        function onCurrentTextChanged() {
            if (passwordInput.text
                    !== root.context.currentText)
                passwordInput.text =
                    root.context.currentText;
        }

        function onUnlockFailed() {
            passwordInput.clear();
            passwordInput.forceActiveFocus();
            failureShake.restart();
        }
    }

    SequentialAnimation {
        id: failureShake

        NumberAnimation {
            target: authCard
            property: "x"
            to: -Appearance.px(8)
            duration: 55
        }
        NumberAnimation {
            target: authCard
            property: "x"
            to: Appearance.px(8)
            duration: 80
        }
        NumberAnimation {
            target: authCard
            property: "x"
            to: 0
            duration: 55
        }
    }

    component LockCard: Rectangle {
        color: Appearance.layer2
        radius: Appearance.normalRadius
        border.width: 1
        border.color: Appearance.outline
        clip: true
    }

    component DetailLine: RowLayout {
        required property string icon
        required property string label
        required property string value

        spacing: Appearance.px(8)

        Text {
            text: icon
            color: Appearance.primary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(15)
            }
        }

        Text {
            Layout.fillWidth: true
            text: label
            color: Appearance.subtext
            elide: Text.ElideRight
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }

        Text {
            text: value
            color: Appearance.layer0Text
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
                weight: Font.DemiBold
            }
        }
    }

    component ResourceGauge: ColumnLayout {
        id: gauge

        required property string icon
        required property string label
        required property real value
        required property string valueText

        spacing: Appearance.px(5)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(7)

            Text {
                text: gauge.icon
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(15)
                }
            }

            Text {
                Layout.fillWidth: true
                text: gauge.label
                color: Appearance.subtext
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }

            Text {
                text: gauge.valueText
                color: Appearance.layer0Text
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                    weight: Font.DemiBold
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(6)
            radius: Appearance.fullRadius
            color: Appearance.layer3

            Rectangle {
                width: parent.width * Math.max(
                    0, Math.min(1, gauge.value))
                height: parent.height
                radius: parent.radius
                color: Appearance.primary

                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.spatialDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    component NetworkRate: Rectangle {
        id: networkRate

        required property string icon
        required property string label
        required property string value

        implicitHeight: Appearance.px(40)
        radius: Appearance.px(10)
        color: Appearance.layer3
        border.width: 1
        border.color: Appearance.layer0Border

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(9)
                rightMargin: Appearance.px(9)
            }
            spacing: Appearance.px(7)

            Text {
                text: networkRate.icon
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(16)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: networkRate.label
                    color: Appearance.subtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.px(9)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: networkRate.value
                    color: Appearance.layer0Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: Appearance.smallFontSize
                        weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
