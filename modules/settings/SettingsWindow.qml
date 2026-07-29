pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common

ApplicationWindow {
    id: root

    visible: false
    title: "QuickShell 设置"
    color: Appearance.layer0
    width: Math.min(screen?.width * 0.86 ?? Appearance.px(980),
        Appearance.px(980))
    height: Math.min(screen?.height * 0.86 ?? Appearance.px(760),
        Appearance.px(760))
    minimumWidth: Appearance.px(760)
    minimumHeight: Appearance.px(560)

    function openWindow() {
        show();
        raise();
        requestActivate();
    }

    function closeWindow() {
        hide();
    }

    function toggleWindow() {
        if (visible)
            closeWindow();
        else
            openWindow();
    }

    onClosing: event => {
        event.accepted = false;
        closeWindow();
    }

    Connections {
        target: SettingsLauncher

        function onOpenRequested() {
            root.openWindow();
        }

        function onCloseRequested() {
            root.closeWindow();
        }

        function onToggleRequested() {
            root.toggleWindow();
        }
    }

    IpcHandler {
        target: "settingsWindow"

        function open(): void {
            root.openWindow();
        }

        function close(): void {
            root.closeWindow();
        }

        function toggle(): void {
            root.toggleWindow();
        }

        function visible(): bool {
            return root.visible;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.layer0

        RowLayout {
            anchors {
                fill: parent
                margins: Appearance.px(10)
            }
            spacing: Appearance.px(10)

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Appearance.px(190)
                radius: Appearance.normalRadius
                color: Appearance.layer1
                border.width: 1
                border.color: Appearance.layer0Border

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Appearance.px(14)
                    }
                    spacing: Appearance.px(10)

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Appearance.px(12)
                        spacing: Appearance.px(10)

                        Rectangle {
                            implicitWidth: Appearance.px(42)
                            implicitHeight: Appearance.px(42)
                            radius: Appearance.px(13)
                            color: Appearance.primaryContainer

                            Text {
                                anchors.centerIn: parent
                                text: "󰣇"
                                color: Appearance.primaryContainerText
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(24)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "QuickShell"
                                color: Appearance.layer0Text
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.largeFontSize
                                    weight: Font.DemiBold
                                }
                            }

                            Text {
                                text: "设置"
                                color: Appearance.subtext
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.smallFontSize
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Appearance.px(42)
                        radius: Appearance.px(12)
                        color: Appearance.secondaryContainer

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.px(10)

                            Text {
                                text: "󰒓"
                                color: Appearance.secondaryContainerText
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "快速设置"
                                color: Appearance.secondaryContainerText
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.normalRadius
                color: Appearance.layer2
                border.width: 1
                border.color: Appearance.layer0Border
                clip: true

                SettingsContent {
                    anchors.fill: parent
                    onCloseRequested: root.closeWindow()
                }
            }
        }
    }
}
