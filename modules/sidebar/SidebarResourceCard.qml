pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: root

    component MetricRow: RowLayout {
        id: metric

        required property string icon
        required property string label
        required property string valueText
        required property real value
        property bool warning: false

        Layout.fillWidth: true
        spacing: Appearance.px(8)

        Text {
            text: metric.icon
            color: metric.warning
                ? Theme.palette.m3error : Appearance.primary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(16)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(4)

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: metric.label
                    color: Appearance.layer1Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                Text {
                    text: metric.valueText
                    color: metric.warning
                        ? Theme.palette.m3error : Appearance.layer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                        weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(5)
                radius: Appearance.fullRadius
                color: Appearance.layer1
                clip: true

                Rectangle {
                    width: parent.width * Math.max(0,
                        Math.min(1, metric.value))
                    height: parent.height
                    radius: parent.radius
                    color: metric.warning
                        ? Theme.palette.m3error : Appearance.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Appearance.px(28)
    radius: Appearance.smallRadius
    color: Appearance.layer3
    border.width: 1
    border.color: Appearance.outline

    ColumnLayout {
        id: content

        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(12)

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(8)

            Text {
                text: "󰍛"
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(18)
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.tr("systemMonitor")
                color: Appearance.layer0Text
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.fontSize
                    weight: Font.DemiBold
                }
            }
        }

        MetricRow {
            icon: "󰻠"
            label: I18n.tr("cpuUsage")
            value: ResourceService.cpuUsage
            valueText: Math.round(value * 100) + "%"
            warning: value >= 0.9
        }

        MetricRow {
            icon: "󰍛"
            label: I18n.tr("memoryUsage")
            value: ResourceService.memoryUsage
            valueText: Math.round(value * 100) + "%"
            warning: value >= 0.9
        }

        MetricRow {
            visible: ResourceService.temperatureAvailable
            icon: "󰔏"
            label: I18n.tr("cpuTemperature")
            value: ResourceService.cpuTemperature / 100
            valueText: Math.round(
                ResourceService.cpuTemperature) + "°C"
            warning: ResourceService.cpuTemperature >= 85
        }
    }
}
