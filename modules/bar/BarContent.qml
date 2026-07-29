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

    readonly property real compactLevel: width <= Appearance.px(1000) ? 2
        : width <= Appearance.px(1200) ? 1 : 0
    readonly property real sideGroupWidth: compactLevel === 2
        ? Appearance.px(190) : compactLevel === 1
            ? Appearance.px(280) : Appearance.px(360)
    property string outputName: ""
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
            pixelSize: Appearance.fontSize
        }
    }

    component BarIcon: Text {
        color: Appearance.secondaryContainerText
        verticalAlignment: Text.AlignVCenter
        font {
            family: Appearance.iconFontFamily
            pixelSize: Appearance.fontSize + Appearance.px(3)
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
        smoothing: Appearance.px(20)
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
            width: Appearance.px(30)
            height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.showFor(launcherControl, "launcher")

            Rectangle {
                id: launcherPill
                width: Appearance.px(30)
                height: Appearance.px(30)
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
                        pixelSize: Appearance.px(19)
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

        }

        Row {
            id: focusedWindowInfo

            visible: width >= Appearance.px(110)
            height: parent.height
            spacing: Appearance.px(8)
            anchors {
                left: launcherControl.right
                leftMargin: Appearance.px(10)
                right: parent.right
                rightMargin: Appearance.px(10)
            }

            Image {
                id: focusedWindowIcon

                width: visible ? Appearance.px(20) : 0
                height: Appearance.px(20)
                anchors.verticalCenter: parent.verticalCenter
                source: NiriService.focusedWindow?.iconPath
                    ? "file://" + NiriService.focusedWindow.iconPath : ""
                sourceSize.width: Appearance.px(20)
                sourceSize.height: Appearance.px(20)
                smooth: true
                visible: ShellSettings.showActiveWindowIcon && source !== ""
            }

            Column {
                width: Math.max(0, focusedWindowInfo.width
                    - (focusedWindowIcon.visible
                        ? focusedWindowIcon.width + focusedWindowInfo.spacing : 0))
                anchors {
                    verticalCenter: parent.verticalCenter
                }
                spacing: -Appearance.px(2)

                Text {
                    width: parent.width
                    text: NiriService.focusedWindow?.appId ?? "Desktop"
                    color: Appearance.subtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                Text {
                    width: parent.width
                    text: NiriService.focusedWindow?.title ?? "No focused window"
                    color: Appearance.layer0Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.fontSize
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
        spacing: Appearance.px(4)

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
                    Layout.leftMargin: Appearance.px(5)
                }

                BarText {
                    visible: root.compactLevel < 2
                    text: "18"
                }

                Rectangle {
                    visible: root.compactLevel === 0
                    Layout.leftMargin: Appearance.px(5)
                    implicitWidth: Appearance.px(20)
                    implicitHeight: Appearance.px(20)
                    radius: Appearance.fullRadius
                    color: Appearance.secondaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        color: Appearance.secondaryContainerText
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.fontSize
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

        WorkspaceSwitcher {
            anchors.verticalCenter: parent.verticalCenter
            outputName: root.outputName
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
                    font.pixelSize: Appearance.largeFontSize
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

                Rectangle {
                    visible: root.compactLevel < 2
                    Layout.leftMargin: Appearance.px(8)
                    implicitWidth: Appearance.px(45)
                    implicitHeight: Appearance.px(20)
                    radius: Appearance.px(5)
                    color: Appearance.secondaryContainer

                    Row {
                        anchors.centerIn: parent
                        spacing: Appearance.px(2)

                        Text {
                            text: "󰁹"
                            color: Appearance.secondaryContainerText
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.fontSize - Appearance.px(1)
                            }
                        }

                        Text {
                            text: "100"
                            color: Appearance.secondaryContainerText
                            font {
                                family: Appearance.fontFamily
                                pixelSize: Appearance.smallFontSize
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
                ? auxiliaryStatusRow.width + Appearance.px(14) : 0)
            height: parent.height
            hoverEnabled: true
            onClicked: popup.showFor(statusControl, "status")
            anchors {
                right: parent.right
                rightMargin: Appearance.px(4)
            }

            Rectangle {
                id: statusPill
                implicitWidth: statusRow.implicitWidth + Appearance.px(20)
                implicitHeight: Appearance.px(30)
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
                    spacing: Appearance.px(14)

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
                    rightMargin: Appearance.px(14)
                    verticalCenter: parent.verticalCenter
                }
                spacing: Appearance.px(13)

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

        MouseArea {
            id: settingsControl

            anchors {
                right: statusControl.left
                rightMargin: Appearance.cornerSize
            }
            width: Appearance.px(30)
            height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SettingsLauncher.open()

            Rectangle {
                width: Appearance.px(30)
                height: Appearance.px(30)
                anchors.verticalCenter: parent.verticalCenter
                radius: Appearance.fullRadius
                color: settingsControl.containsMouse
                    ? Appearance.layer1Hover : "transparent"
                scale: settingsControl.pressed ? 0.88 : 1

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: Appearance.layer0Text
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(17)
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
        }
    }

    StyledPopup {
        id: popup
        z: -1
        deformMatrix: popupBackground.deformMatrix
    }
}
