pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    signal activated

    readonly property int percentageTextWidth:
        Math.ceil(percentageWidthMeasure.implicitWidth)
    readonly property int temperatureTextWidth:
        Math.ceil(temperatureWidthMeasure.implicitWidth)

    readonly property var shownResources: {
        const resources = [];
        if (ShellSettings.showCpuUsage) {
            resources.push({
                key: "cpu",
                icon: "󰻠",
                value: ResourceService.cpuUsage,
                text: Math.round(ResourceService.cpuUsage * 100) + "%",
                warning: ResourceService.cpuUsage >= 0.9
            });
        }
        if (ShellSettings.showMemoryUsage) {
            resources.push({
                key: "memory",
                icon: "󰍛",
                value: ResourceService.memoryUsage,
                text: Math.round(ResourceService.memoryUsage * 100) + "%",
                warning: ResourceService.memoryUsage >= 0.9
            });
        }
        if (ShellSettings.showCpuTemperature) {
            const available = ResourceService.temperatureAvailable;
            resources.push({
                key: "temperature",
                icon: "󰔏",
                value: available
                    ? ResourceService.cpuTemperature / 100 : 0,
                text: available
                    ? Math.round(ResourceService.cpuTemperature) + "°C"
                    : "--°C",
                warning: available
                    && ResourceService.cpuTemperature >= 85
            });
        }
        return resources;
    }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: performanceRow.implicitWidth + Appearance.px(18)
    implicitHeight: Appearance.barHeight
    onClicked: activated()

    function textWidthFor(resourceKey) {
        return resourceKey === "temperature"
            ? temperatureTextWidth : percentageTextWidth;
    }

    Text {
        id: percentageWidthMeasure

        visible: false
        text: "888%"
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.smallFontSize
        }
    }

    Text {
        id: temperatureWidthMeasure

        visible: false
        text: "888°C"
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.smallFontSize
        }
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: root.containsMouse
            ? Appearance.layer1Hover : Appearance.layer1
        border.width: 1
        border.color: Appearance.layer0Border

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation { duration: Appearance.fastDuration }
        }
    }

    RowLayout {
        id: performanceRow

        anchors.centerIn: parent
        spacing: Appearance.px(7)

        Text {
            visible: root.shownResources.length === 0
            text: "󰍛"
            color: Appearance.layer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(18)
            }
        }

        Repeater {
            model: root.shownResources

            delegate: RowLayout {
                required property var modelData
                spacing: Appearance.px(3)

                ResourceRing {
                    icon: parent.modelData.icon
                    value: parent.modelData.value
                    warning: parent.modelData.warning
                }

                Text {
                    readonly property int reservedWidth:
                        root.textWidthFor(parent.modelData.key)

                    Layout.minimumWidth: reservedWidth
                    Layout.preferredWidth: reservedWidth
                    Layout.maximumWidth: reservedWidth
                    text: parent.modelData.text
                    color: parent.modelData.warning
                        ? Theme.palette.m3error : Appearance.layer0Text
                    horizontalAlignment: Text.AlignLeft
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }
        }
    }
}
