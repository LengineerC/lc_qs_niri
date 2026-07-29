pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

// Horizontal adaptation of Caelestia's popouts/ClipWrapper + Wrapper.
// This item must live in the same layer-shell window as the bar.
Item {
    id: root

    readonly property Item popupMaskItem: root
    readonly property int moveDuration: 500
    readonly property var moveCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property real targetCenter: {
        const screenWidth = parent?.width ?? popupWidth;
        const rawCenter = anchorItem
            ? anchorItem.mapToItem(parent, anchorItem.width / 2, 0).x
            : screenWidth / 2;
        const halfWidth = popupWidth / 2;
        return Math.max(Appearance.elevationMargin + halfWidth,
            Math.min(screenWidth - Appearance.elevationMargin - halfWidth,
                rawCenter));
    }

    property Item anchorItem: null
    property string page: ""
    property bool shown: false
    property real offsetScale: shown ? 0 : 1
    property var deformMatrix

    property string popupIcon: "󰋼"
    property string popupTitle: ""
    property var popupRows: []
    property int popupWidth: 340
    property int popupHeight: 150

    x: targetCenter - popupWidth / 2
    y: Appearance.barHeight
    width: popupWidth
    height: popupContent.height * (1 - offsetScale)
    visible: width > 0 && height > 0
    clip: true

    function configure(pageName) {
        page = pageName;
        switch (pageName) {
        case "launcher":
            popupIcon = "󰣇";
            popupTitle = "Quick shell";
            popupWidth = 310;
            popupHeight = 164;
            popupRows = [
                { icon: "󰍹", label: "Desktop", value: "Workspace 1" },
                { icon: "󰌾", label: "Session", value: "Active" },
                { icon: "󰐥", label: "Power menu", value: "Unavailable" }
            ];
            break;
        case "resources":
            popupIcon = "󰍛";
            popupTitle = "System resources";
            popupWidth = 410;
            popupHeight = 164;
            popupRows = [
                { icon: "󰍛", label: "RAM used", value: "42%" },
                { icon: "󰓡", label: "Swap used", value: "0%" },
                { icon: "󰻠", label: "CPU load", value: "18%" }
            ];
            break;
        case "workspaces":
            popupIcon = "󰕮";
            popupTitle = "Workspaces";
            popupWidth = 330;
            popupHeight = 142;
            popupRows = [
                { icon: "󰮯", label: "Current workspace", value: "1" },
                { icon: "󰁍", label: "Scroll on the bar", value: "Switch" }
            ];
            break;
        case "clock":
            popupIcon = "󰃭";
            popupTitle = Qt.locale().toString(new Date(), "dddd, MMMM dd");
            popupWidth = 380;
            popupHeight = 164;
            popupRows = [
                { icon: "󰔛", label: "System uptime", value: "--" },
                { icon: "󰄬", label: "To do", value: "No pending tasks" },
                { icon: "󰥔", label: "Time zone", value: "Local" }
            ];
            break;
        case "status":
            popupIcon = "󰒓";
            popupTitle = "System status";
            popupWidth = 370;
            popupHeight = 208;
            popupRows = [
                { icon: "󰤨", label: "Network", value: "Connected" },
                { icon: "󰂯", label: "Bluetooth", value: "On" },
                { icon: "󰂚", label: "Notifications", value: "No unread" },
                { icon: "󰁹", label: "Battery", value: "100%" },
                { icon: "󰏘", label: "Wallpaper palette",
                    value: Theme.generating ? "Generating…" : Theme.scheme.replace("scheme-", "") }
            ];
            break;
        default:
            popupIcon = "󰝚";
            popupTitle = "Media";
            popupWidth = 370;
            popupHeight = 142;
            popupRows = [
                { icon: "󰝚", label: "No media playing", value: "" },
                { icon: "󰐊", label: "Player controls", value: "Unavailable" }
            ];
        }
    }

    function showFor(target, pageName) {
        if (shown && anchorItem === target && page === pageName) {
            close();
            return;
        }

        configure(pageName);
        anchorItem = target;
        shown = true;
    }

    function close() {
        shown = false;
    }

    Behavior on offsetScale {
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.moveCurve
        }
    }

    Behavior on x {
        enabled: root.offsetScale < 1
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.moveCurve
        }
    }

    Behavior on width {
        enabled: root.offsetScale < 1
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.moveCurve
        }
    }

    Item {
        id: popupContent

        width: root.width
        height: root.popupHeight
        y: (-height - 5) * root.offsetScale
        opacity: 1 - root.offsetScale
        transform: Matrix4x4 {
            matrix: root.deformMatrix
        }

        MouseArea {
            anchors.fill: parent
        }

        Behavior on height {
            enabled: root.offsetScale < 1
            NumberAnimation {
                duration: root.moveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.moveCurve
            }
        }

        Rectangle {
            id: innerSurface

            x: 7
            y: 7
            width: parent.width - 14
            height: root.popupHeight - 14
            radius: Appearance.smallRadius
            color: Appearance.layer2
            border.width: 1
            border.color: Appearance.layer0Border
        }

        ColumnLayout {
            x: 21
            y: 18
            width: parent.width - 42
            height: root.popupHeight - 36
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.popupIcon
                    color: Appearance.layer1Text
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: 18
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.popupTitle
                    color: Appearance.layer1Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 15
                        weight: Font.DemiBold
                    }
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: Appearance.fullRadius
                    color: closeArea.containsMouse
                        ? Appearance.layer1Active : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Appearance.subtext
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.close()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.fastDuration
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.outline
                opacity: 0.55
            }

            Repeater {
                model: root.popupRows

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 7

                    Text {
                        text: modelData.icon
                        color: Appearance.layer1Text
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: 16
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: Appearance.layer1Text
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: 13
                        }
                    }

                    Text {
                        text: modelData.value
                        color: Appearance.subtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: 12
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
