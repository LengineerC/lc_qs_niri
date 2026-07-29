pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "file:///home/lengineerc/Applications/qs/test/Caelestia/Blobs" as Blobs
import qs.common

Item {
    id: root

    implicitHeight: Appearance.barHeight
    readonly property Item popupMask: popup.popupMaskItem
    readonly property bool popupShown: popup.shown
    readonly property bool hostWindowActive: Window.active

    readonly property real compactLevel: width <= 1000 ? 2 : width <= 1200 ? 1 : 0
    readonly property real sideGroupWidth: compactLevel === 2 ? 190
        : compactLevel === 1 ? 280 : 360
    property string currentTime: Qt.locale().toString(new Date(), "hh:mm")
    property string currentDate: Qt.locale().toString(new Date(), "MMM dd")

    function closePopup() {
        popup.close();
    }

    component BarText: Text {
        color: Appearance.layer1Text
        verticalAlignment: Text.AlignVCenter
        font {
            family: Appearance.fontFamily
            pixelSize: 13
        }
    }

    component BarIcon: Text {
        color: Appearance.secondaryContainerText
        verticalAlignment: Text.AlignVCenter
        font {
            family: Appearance.iconFontFamily
            pixelSize: 16
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            root.currentTime = Qt.locale().toString(now, "hh:mm");
            root.currentDate = Qt.locale().toString(now, "MMM dd");
        }
    }

    Blobs.BlobGroup {
        id: barBlobGroup

        color: Appearance.barBgColor
        smoothing: 20
    }

    Blobs.BlobRect {
        id: barBackground

        z: -2
        anchors.fill: parent
        group: barBlobGroup
        radius: 0
        deformScale: 0

        MouseArea {
            anchors.fill: parent
            onClicked: popup.close()
        }
    }

    Blobs.BlobRect {
        id: popupBackground

        readonly property real extraHeight: 0.2

        z: -2
        visible: height > 0
        group: barBlobGroup
        x: popup.x
        y: Appearance.barHeight - popup.height * extraHeight
        width: popup.width
        height: popup.height * (1 + extraHeight)
        radius: Appearance.normalRadius
        deformScale: 0.000015
    }

    Item {
        id: leftArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }

        MouseArea {
            id: launcherControl
            x: Appearance.cornerSize
            width: root.compactLevel === 0
                ? Math.min(parent.width - Appearance.cornerSize,
                    launcherPill.width + 10 + launcherLabels.implicitWidth)
                : 30
            height: parent.height
            hoverEnabled: true
            onClicked: popup.showFor(launcherControl, "launcher")

            Rectangle {
                id: launcherPill
                width: 30
                height: 30
                anchors.verticalCenter: parent.verticalCenter
                radius: Appearance.fullRadius
                color: launcherControl.containsMouse
                    || popup.shown && popup.anchorItem === launcherControl
                    ? Appearance.secondaryContainer : "transparent"
                scale: launcherControl.pressed ? 0.88 : 1

                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    color: Appearance.layer0Text
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: 19
                    }
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
                id: launcherLabels
                visible: root.compactLevel === 0
                anchors {
                    left: launcherPill.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: -2

                Text {
                    text: "Desktop"
                    color: Appearance.subtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 11
                    }
                }

                Text {
                    text: "Workspace 1"
                    color: Appearance.layer0Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 13
                    }
                }
            }
        }
    }

    Row {
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        Item {
            width: root.sideGroupWidth
            height: parent.height

            BarGroup {
                id: resourcesGroup
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                onClicked: popup.showFor(resourcesGroup, "resources")

                BarIcon {
                    text: "󰍛"
                }

                BarText {
                    text: "42"
                }

                BarIcon {
                    visible: root.compactLevel < 2
                    text: "󰻠"
                    Layout.leftMargin: 5
                }

                BarText {
                    visible: root.compactLevel < 2
                    text: "18"
                }

                Rectangle {
                    visible: root.compactLevel === 0
                    Layout.leftMargin: 5
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: Appearance.fullRadius
                    color: Appearance.secondaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        color: Appearance.secondaryContainerText
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: 13
                        }
                    }
                }

                BarText {
                    visible: root.compactLevel === 0
                    text: "No media"
                    elide: Text.ElideRight
                }
            }
        }

        BarGroup {
            id: workspaceGroup
            anchors.verticalCenter: parent.verticalCenter
            padding: 5
            onClicked: popup.showFor(workspaceGroup, "workspaces")

            Row {
                spacing: 0

                Repeater {
                    model: 5

                    delegate: Item {
                        required property int index
                        width: 26
                        height: 26

                        Rectangle {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: Appearance.fullRadius
                            color: index === 0
                                ? Appearance.secondaryContainer : "transparent"

                            Rectangle {
                                anchors.centerIn: parent
                                width: index === 0 ? 7 : 5
                                height: width
                                radius: Appearance.fullRadius
                                color: index === 0
                                    ? Appearance.secondaryContainerText
                                    : index < 3 ? Appearance.subtext : Appearance.outline

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Appearance.spatialDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Appearance.spatialCurve
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

        Item {
            width: root.sideGroupWidth
            height: parent.height

            BarGroup {
                id: clockGroup
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                onClicked: popup.showFor(clockGroup, "clock")

                BarText {
                    text: root.currentTime
                    font.pixelSize: 16
                }

                BarText {
                    visible: root.compactLevel < 2
                    text: "•"
                    color: Appearance.subtext
                }

                BarText {
                    visible: root.compactLevel < 2
                    text: root.currentDate
                }

                BarIcon {
                    visible: root.compactLevel === 0
                    Layout.leftMargin: 10
                    text: "󰒓"
                }

                Rectangle {
                    visible: root.compactLevel < 2
                    Layout.leftMargin: 8
                    implicitWidth: 45
                    implicitHeight: 20
                    radius: 5
                    color: Appearance.secondaryContainer

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "󰁹"
                            color: Appearance.secondaryContainerText
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: 12
                            }
                        }

                        Text {
                            text: "100"
                            color: Appearance.secondaryContainerText
                            font {
                                family: Appearance.fontFamily
                                pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: rightArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }

        MouseArea {
            id: statusControl
            width: statusPill.width + (root.compactLevel === 0
                ? auxiliaryStatusRow.width + 14 : 0)
            height: parent.height
            hoverEnabled: true
            onClicked: popup.showFor(statusControl, "status")
            anchors {
                right: parent.right
                rightMargin: Appearance.cornerSize
            }

            Rectangle {
                id: statusPill
                implicitWidth: statusRow.implicitWidth + 20
                implicitHeight: 30
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                radius: Appearance.fullRadius
                color: statusControl.containsMouse
                    || popup.shown && popup.anchorItem === statusControl
                    ? Appearance.layer1Hover : "transparent"
                scale: statusControl.pressed ? 0.94 : 1

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 14

                    BarIcon {
                        text: "󰌾"
                        color: Appearance.layer0Text
                    }

                    BarIcon {
                        text: "󰤨"
                        color: Appearance.layer0Text
                    }

                    BarIcon {
                        visible: root.compactLevel < 2
                        text: "󰂯"
                        color: Appearance.layer0Text
                    }
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

            Row {
                id: auxiliaryStatusRow
                visible: root.compactLevel === 0
                anchors {
                    right: statusPill.left
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: 13

                BarIcon {
                    text: "󰂚"
                    color: Appearance.subtext
                }

                BarIcon {
                    text: "󰖐"
                    color: Appearance.subtext
                }
            }
        }
    }

    StyledPopup {
        id: popup
        z: -1
        deformMatrix: popupBackground.deformMatrix
    }
}
