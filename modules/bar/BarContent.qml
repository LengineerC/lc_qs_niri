pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "file:///home/lengineerc/Applications/qs/test/Caelestia/Blobs" as Blobs
import qs.common
import qs.services

Item {
    id: root

    implicitHeight: Appearance.barHeight
    readonly property Item barMask: barInputRegion
    readonly property Item popupMask: popup.popupMaskItem
    readonly property bool popupShown: popup.shown
    readonly property bool popupContainsMouse: popup.pointerInside
    readonly property bool hostWindowActive: Window.active
    readonly property int edgeMargin: Appearance.cornerSize

    property real effectsOpacity: 1
    readonly property real compactLevel: width <= Appearance.px(1000) ? 2
        : width <= Appearance.px(1200) ? 1 : 0
    readonly property real sideGroupWidth: compactLevel === 2
        ? Appearance.px(190) : compactLevel === 1
            ? Appearance.px(280) : Appearance.px(360)
    property string outputName: ""

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

    // A full-height root is required for pointer delivery to the popup, while
    // this smaller item keeps the layer-shell input region limited to the bar.
    Item {
        id: barInputRegion

        width: root.width
        height: Appearance.barHeight
    }

    Item {
        id: shadowSurface

        z: -2
        width: root.width
        height: Math.max(Appearance.barHeight,
            popup.y + popup.height)
            + Math.ceil((ShellSettings.shadowBlurRadius
                + Math.abs(ShellSettings.shadowOffsetY) + 4)
                * Appearance.scale)
        layer.enabled: ShellSettings.shadowEnabled
        layer.effect: MultiEffect {
            shadowEnabled: ShellSettings.shadowEnabled
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Theme.palette.m3shadow,
                ShellSettings.shadowOpacity
                    * Math.max(0, Math.min(1, root.effectsOpacity)))
            shadowVerticalOffset: Math.round(
                ShellSettings.shadowOffsetY * Appearance.scale)
        }

        Blobs.BlobGroup {
            id: barBlobGroup

            color: Appearance.barBgColor
            smoothing: Appearance.px(20)
        }

        Blobs.BlobRect {
            id: barBackground

            x: 0
            y: 0
            width: parent.width
            height: Appearance.barHeight
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

            visible: popup.revealProgress > 0
            group: barBlobGroup
            x: popup.x
            y: Appearance.barHeight - popup.height * extraHeight
            width: visible ? popup.width : 0
            height: visible
                ? popup.height * (1 + extraHeight) : 0
            radius: Appearance.normalRadius
            deformScale: 0.000015
        }
    }

    Item {
        id: leftArea
        anchors {
            top: parent.top
            left: parent.left
            right: middleSection.left
        }
        height: Appearance.barHeight

        MouseArea {
            id: launcherControl
            x: root.edgeMargin
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
                    text: NiriService.focusedWindow?.appId
                        ?? I18n.tr("desktop")
                    color: Appearance.subtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                Text {
                    width: parent.width
                    text: NiriService.focusedWindow?.title
                        ?? I18n.tr("noFocusedWindow")
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
            horizontalCenter: parent.horizontalCenter
        }
        height: Appearance.barHeight
        spacing: Appearance.px(4)

        WorkspaceSwitcher {
            anchors.verticalCenter: parent.verticalCenter
            outputName: root.outputName
        }

        Item {
            width: root.sideGroupWidth
            height: parent.height

            TimeModule {
                id: timeModule

                showDate: root.compactLevel < 2
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                onActivated: popup.showFor(timeModule, "calendar")
            }
        }
    }

    Item {
        id: rightArea
        anchors {
            top: parent.top
            left: middleSection.right
            right: parent.right
        }
        height: Appearance.barHeight

        BatteryModule {
            id: batteryModule

            anchors {
                right: systemModule.left
                rightMargin: Appearance.px(4)
                verticalCenter: parent.verticalCenter
            }
            onActivated: popup.showFor(batteryModule, "battery")
        }

        SystemModule {
            id: systemModule

            compact: root.compactLevel > 0
            anchors {
                right: parent.right
                rightMargin: root.edgeMargin
            }
            
            onActivated: popup.showFor(systemModule, "system")
        }

        ClipboardModule {
            id: clipboardModule

            anchors {
                right: settingsControl.left
                rightMargin: Appearance.px(4)
                verticalCenter: parent.verticalCenter
            }
            onActivated: popup.showFor(clipboardModule, "clipboard")
        }

        NotificationModule {
            id: notificationModule

            anchors {
                right: clipboardModule.left
                rightMargin: Appearance.px(3)
                verticalCenter: parent.verticalCenter
            }
            onActivated:
                popup.showFor(notificationModule, "notifications")
        }

        MouseArea {
            id: settingsControl

            anchors {
                right: batteryModule.left
                rightMargin: Appearance.px(4)
                verticalCenter: parent.verticalCenter
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
        z: 10
        deformMatrix: popupBackground.deformMatrix
    }
}
