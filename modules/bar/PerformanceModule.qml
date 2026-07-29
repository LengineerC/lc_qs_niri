pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    signal activated

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
                    ? Math.round(ResourceService.cpuTemperature) + "°"
                    : "--°",
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
                    text: parent.modelData.text
                    color: parent.modelData.warning
                        ? Theme.palette.m3error : Appearance.layer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }
        }
    }
}
