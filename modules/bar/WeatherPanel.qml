pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    implicitWidth: Appearance.px(850)
    implicitHeight: contentColumn.implicitHeight + Appearance.px(28)

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component DetailMetric: RowLayout {
        id: metric

        required property string icon
        required property string label
        required property string value

        spacing: Appearance.px(8)

        Text {
            text: metric.icon
            color: Appearance.primary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(17)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PanelText {
                text: metric.label
                color: Appearance.subtext
                font.pixelSize: Appearance.smallFontSize
            }

            PanelText {
                text: metric.value
                color: Appearance.layer0Text
                font {
                    pixelSize: Appearance.fontSize + 1
                    weight: Font.DemiBold
                }
            }
        }
    }

    component ForecastValue: RowLayout {
        id: forecastValue

        required property string icon
        required property string value
        property color valueColor: Appearance.subtext

        spacing: Appearance.px(5)

        Text {
            text: forecastValue.icon
            color: Appearance.primary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(12)
            }
        }

        PanelText {
            text: forecastValue.value
            color: forecastValue.valueColor
            font.pixelSize: Appearance.smallFontSize
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
        spacing: Appearance.px(9)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            Text {
                text: WeatherService.currentIcon
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(22)
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: I18n.tr("weather")
                color: Appearance.layer0Text
                font {
                    pixelSize: Appearance.largeFontSize
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                implicitWidth: Appearance.px(30)
                implicitHeight: Appearance.px(30)
                radius: Appearance.fullRadius
                color: refreshArea.containsMouse
                    ? Appearance.layer1Active : "transparent"
                opacity: WeatherService.loading ? 0.55 : 1

                Text {
                    id: refreshIcon

                    anchors.centerIn: parent
                    text: "󰑐"
                    color: Appearance.subtext
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(15)
                    }

                    RotationAnimator {
                        target: refreshIcon
                        running: WeatherService.loading
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    enabled: !WeatherService.loading
                    hoverEnabled: true
                    cursorShape: enabled
                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: WeatherService.refresh()
                }
            }

            CloseButton {
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(144)
            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(16)
                }
                visible: WeatherService.ready
                spacing: Appearance.px(22)

                RowLayout {
                    Layout.preferredWidth: Appearance.px(330)
                    spacing: Appearance.px(16)

                    Text {
                        text: WeatherService.currentIcon
                        color: Appearance.primary
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(54)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(2)

                        RowLayout {
                            spacing: Appearance.px(3)

                            PanelText {
                                text:
                                    WeatherService.currentTemperature
                                color: Appearance.layer0Text
                                font {
                                    pixelSize: Appearance.px(30)
                                    weight: Font.Medium
                                }
                            }
                        }

                        PanelText {
                            Layout.fillWidth: true
                            text: WeatherService.description(
                                WeatherService.current.weatherCode)
                            color: Appearance.layer0Text
                            elide: Text.ElideRight
                            font.pixelSize:
                                Appearance.fontSize + 1
                        }

                        PanelText {
                            text: I18n.tr("feelsLike") + " "
                                + WeatherService.formatTemperature(
                                    WeatherService.current
                                        .apparentTemperature)
                            color: Appearance.subtext
                            font.pixelSize: Appearance.smallFontSize
                        }

                        RowLayout {
                            spacing: Appearance.px(5)

                            Text {
                                text: "󰍎"
                                color: Appearance.primary
                                font {
                                    family:
                                        Appearance.iconFontFamily
                                    pixelSize: Appearance.px(13)
                                }
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: WeatherService.locationName
                                color: Appearance.subtext
                                elide: Text.ElideRight
                                font.pixelSize:
                                    Appearance.smallFontSize
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: Appearance.outline
                    opacity: 0.7
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: Appearance.px(12)
                    columnSpacing: Appearance.px(18)
                    uniformCellWidths: true

                    DetailMetric {
                        Layout.fillWidth: true
                        icon: "󰖎"
                        label: I18n.tr("humidity")
                        value: WeatherService.formatPercent(
                            WeatherService.current.humidity)
                    }
                    DetailMetric {
                        Layout.fillWidth: true
                        icon: "󰖝"
                        label: I18n.tr("windSpeed")
                        value: WeatherService.formatWind(
                            WeatherService.current.windSpeed)
                    }
                    DetailMetric {
                        Layout.fillWidth: true
                        icon: "󰒋"
                        label: I18n.tr("pressure")
                        value: WeatherService.formatPressure(
                            WeatherService.current.pressure)
                    }
                    DetailMetric {
                        Layout.fillWidth: true
                        icon: "󰖗"
                        label: I18n.tr("precipitation")
                        value: WeatherService.formatPercent(
                            WeatherService.current
                                .precipitationProbability)
                    }
                    DetailMetric {
                        Layout.fillWidth: true
                        icon: "󰖜"
                        label: I18n.tr("sunrise")
                        value: WeatherService.timeFromIso(
                            WeatherService.current.sunrise)
                    }
                    DetailMetric {
                        Layout.fillWidth: true
                        icon: "󰖛"
                        label: I18n.tr("sunset")
                        value: WeatherService.timeFromIso(
                            WeatherService.current.sunset)
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: !WeatherService.ready
                spacing: Appearance.px(8)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: WeatherService.loading ? "󰔟" : "󰅚"
                    color: Appearance.primary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(28)
                    }
                }

                PanelText {
                    text: WeatherService.loading
                        ? I18n.tr("weatherLoading")
                        : I18n.tr("weatherUnavailable")
                    color: Appearance.subtext
                }
            }
        }

        PanelText {
            text: I18n.tr("hourlyForecast")
            color: Appearance.layer0Text
            font.weight: Font.DemiBold
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            Repeater {
                model: WeatherService.hourlyForecast

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: Appearance.px(184)
                    radius: Appearance.smallRadius
                    color: index === 0
                        ? Appearance.primaryContainer
                        : Appearance.layer3
                    border.width: 1
                    border.color: index === 0
                        ? Appearance.primary : Appearance.outline

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.px(3)

                        PanelText {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherService.timeFromIso(
                                modelData.time)
                            color: index === 0
                                ? Appearance.primaryContainerText
                                : Appearance.layer0Text
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherService.icon(
                                modelData.weatherCode,
                                modelData.isDay)
                            color: index === 0
                                ? Appearance.primaryContainerText
                                : Appearance.primary
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(25)
                            }
                        }

                        ForecastValue {
                            icon: "󰔏"
                            value: WeatherService.formatTemperature(
                                modelData.temperature)
                            valueColor: index === 0
                                ? Appearance.primaryContainerText
                                : Appearance.layer0Text
                        }
                        ForecastValue {
                            icon: "󱩎"
                            value: WeatherService.formatTemperature(
                                modelData.apparentTemperature)
                        }
                        ForecastValue {
                            icon: "󰖎"
                            value: WeatherService.formatPercent(
                                modelData.humidity)
                        }
                        ForecastValue {
                            icon: "󰖝"
                            value: WeatherService.formatWind(
                                modelData.windSpeed)
                        }
                        ForecastValue {
                            icon: "󰒋"
                            value: WeatherService.formatPressure(
                                modelData.pressure)
                        }
                        ForecastValue {
                            icon: "󰖗"
                            value: WeatherService.formatPercent(
                                modelData.precipitationProbability)
                        }
                        ForecastValue {
                            icon: "󰈈"
                            value: WeatherService.formatVisibility(
                                modelData.visibility)
                        }
                    }
                }
            }
        }

        PanelText {
            text: I18n.tr("dailyForecast")
            color: Appearance.layer0Text
            font.weight: Font.DemiBold
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(7)

            Repeater {
                model: WeatherService.dailyForecast

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: Appearance.px(126)
                    radius: Appearance.smallRadius
                    color: index === 0
                        ? Appearance.primaryContainer
                        : Appearance.layer3
                    border.width: 1
                    border.color: index === 0
                        ? Appearance.primary : Appearance.outline

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.px(3)

                        PanelText {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherService.dayName(
                                modelData.date)
                            color: index === 0
                                ? Appearance.primaryContainerText
                                : Appearance.layer0Text
                            font.weight: Font.DemiBold
                        }

                        PanelText {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherService.shortDate(
                                modelData.date)
                            color: Appearance.subtext
                            font.pixelSize:
                                Appearance.smallFontSize
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherService.icon(
                                modelData.weatherCode, 1)
                            color: index === 0
                                ? Appearance.primaryContainerText
                                : Appearance.primary
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(23)
                            }
                        }

                        PanelText {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherService.formatTemperature(
                                modelData.temperatureMax)
                                + " / "
                                + WeatherService.formatTemperature(
                                    modelData.temperatureMin)
                            color: index === 0
                                ? Appearance.primaryContainerText
                                : Appearance.layer0Text
                            font {
                                pixelSize: Appearance.smallFontSize
                                weight: Font.DemiBold
                            }
                        }

                        ForecastValue {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "󰖗"
                            value: WeatherService.formatPercent(
                                modelData.precipitationProbability)
                        }
                    }
                }
            }
        }

        PanelText {
            Layout.alignment: Qt.AlignRight
            visible: WeatherService.error !== ""
            text: WeatherService.error
            color: Theme.palette.m3error
            elide: Text.ElideRight
            font.pixelSize: Appearance.smallFontSize
        }
    }
}
