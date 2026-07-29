pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.services

Item {
    id: root

    required property var notificationEntry

    implicitWidth: Appearance.px(400)
    implicitHeight: toastSurface.implicitHeight + Appearance.px(16)
    property bool entered: false
    property bool componentReady: false
    property bool animateTransitions: false
    property int entryGeneration: 0
    readonly property bool showing:
        entered && !notificationEntry.closing

    function prepareEntry() {
        if (!notificationEntry)
            return;

        entryGeneration += 1;
        const generation = entryGeneration;
        const entry = notificationEntry;
        animateTransitions = false;

        if (entry.toastPresented) {
            // Repeater can recreate or recycle delegates when its array
            // changes. An existing notification must not enter again.
            entered = true;
            Qt.callLater(() => {
                if (generation === entryGeneration
                        && entry === notificationEntry)
                    animateTransitions = true;
            });
            return;
        }

        entry.toastPresented = true;
        entered = false;
        Qt.callLater(() => {
            if (generation !== entryGeneration
                    || entry !== notificationEntry)
                return;
            animateTransitions = true;
            entered = true;
        });
    }

    onNotificationEntryChanged: {
        if (componentReady)
            prepareEntry();
    }

    Component.onCompleted: {
        componentReady = true;
        prepareEntry();
    }

    Rectangle {
        id: toastSurface

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.px(8)
        }
        implicitHeight: toastContent.implicitHeight + Appearance.px(22)
        radius: Appearance.normalRadius
        color: Appearance.layer1
        border.width: 1
        border.color: root.notificationEntry.urgency === 2
            ? Theme.palette.m3error : Appearance.outline

        layer.enabled: ShellSettings.shadowEnabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Theme.palette.m3shadow, ShellSettings.shadowOpacity)
            shadowVerticalOffset: Math.round(
                ShellSettings.shadowOffsetY * Appearance.scale)
        }

        MouseArea {
            anchors.fill: parent
            enabled: !root.notificationEntry.closing
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationService.activate(
                root.notificationEntry)
        }

        RowLayout {
            id: toastContent
            anchors {
                fill: parent
                margins: Appearance.px(11)
            }
            spacing: Appearance.px(11)

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: Appearance.px(54)
                implicitHeight: Appearance.px(54)
                radius: Appearance.fullRadius
                color: Appearance.primaryContainer
                clip: true

                IconImage {
                    anchors {
                        fill: parent
                        margins: Appearance.px(6)
                    }
                    source: NotificationService.iconSource(
                        root.notificationEntry)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(2)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.px(6)

                    Text {
                        Layout.fillWidth: true
                        text: root.notificationEntry.appName
                        color: Appearance.subtext
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                        }
                    }

                    Text {
                        text: I18n.tr("justNow")
                        color: Appearance.subtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.notificationEntry.summary
                        || I18n.tr("notification")
                    color: Appearance.layer0Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.fontSize + Appearance.px(1)
                        weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.notificationEntry.body
                    color: Appearance.layer1Text
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.fontSize
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: Appearance.px(28)
                implicitHeight: Appearance.px(28)
                radius: Appearance.fullRadius
                color: closeArea.containsMouse
                    ? Appearance.layer1Active : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: Appearance.layer1Text
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(15)
                    }
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    z: 2
                    enabled: !root.notificationEntry.closing
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.markRead(
                        root.notificationEntry.notificationId)
                }
            }
        }
    }

    opacity: showing ? 1 : 0
    x: showing ? 0 : Appearance.px(90)
    scale: showing ? 1 : 0.96

    Behavior on opacity {
        enabled: root.animateTransitions
        NumberAnimation {
            duration: root.notificationEntry.closing
                ? NotificationService.toastExitDuration
                : Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        enabled: root.animateTransitions
        NumberAnimation {
            duration: root.notificationEntry.closing
                ? NotificationService.toastExitDuration
                : Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        enabled: root.animateTransitions
        NumberAnimation {
            duration: root.notificationEntry.closing
                ? NotificationService.toastExitDuration
                : Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }
}
