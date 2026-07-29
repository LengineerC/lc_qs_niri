pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.modules.bar

ApplicationWindow {
    id: root

    property int currentPage: 0
    visible: false
    title: "QuickShell " + I18n.tr("settings")
    color: Appearance.layer0
    width: Math.min(screen?.width * 0.86 ?? Appearance.px(980),
        Appearance.px(980))
    height: Math.min(screen?.height * 0.92 ?? Appearance.px(920),
        Appearance.px(920))
    minimumWidth: Appearance.px(760)
    minimumHeight: Appearance.px(620)

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

        function system(): void {
            root.currentPage = 1;
            root.openWindow();
        }

        function quickSettings(): void {
            root.currentPage = 0;
            root.openWindow();
        }

        function style(): void {
            root.currentPage = 2;
            root.openWindow();
        }

        function displays(): void {
            root.currentPage = 3;
            root.openWindow();
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
                Layout.preferredWidth: Appearance.px(
                    I18n.language === "en_US" ? 210 : 190)
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
                                text: I18n.tr("settings")
                                color: Appearance.subtext
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.smallFontSize
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: quickSettingsTab

                        Layout.fillWidth: true
                        implicitHeight: Appearance.px(42)
                        radius: Appearance.px(12)
                        color: root.currentPage === 0
                            ? Appearance.secondaryContainer
                            : quickSettingsMouse.containsMouse
                                ? Appearance.layer1Hover : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.px(10)

                            Text {
                                text: "󰒓"
                                color: root.currentPage === 0
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("quickSettings")
                                color: root.currentPage === 0
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: quickSettingsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = 0
                        }
                    }

                    Rectangle {
                        id: networkTab

                        Layout.fillWidth: true
                        implicitHeight: Appearance.px(42)
                        radius: Appearance.px(12)
                        color: root.currentPage === 1
                            ? Appearance.secondaryContainer
                            : networkMouse.containsMouse
                                ? Appearance.layer1Hover : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.px(10)

                            Text {
                                text: "󰛳"
                                color: root.currentPage === 1
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("networkDevices")
                                color: root.currentPage === 1
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: networkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = 1
                        }
                    }

                    Rectangle {
                        id: displaysTab

                        Layout.fillWidth: true
                        implicitHeight: Appearance.px(42)
                        radius: Appearance.px(12)
                        color: root.currentPage === 3
                            ? Appearance.secondaryContainer
                            : displaysMouse.containsMouse
                                ? Appearance.layer1Hover : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.px(10)

                            Text {
                                text: "󰍹"
                                color: root.currentPage === 3
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("displays")
                                color: root.currentPage === 3
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: displaysMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = 3
                        }
                    }

                    Rectangle {
                        id: styleTab

                        Layout.fillWidth: true
                        implicitHeight: Appearance.px(42)
                        radius: Appearance.px(12)
                        color: root.currentPage === 2
                            ? Appearance.secondaryContainer
                            : styleMouse.containsMouse
                                ? Appearance.layer1Hover : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.px(10)

                            Text {
                                text: "󰏘"
                                color: root.currentPage === 2
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: I18n.tr("style")
                                color: root.currentPage === 2
                                    ? Appearance.secondaryContainerText
                                    : Appearance.layer1Text
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: styleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = 2
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
                    visible: root.currentPage === 0
                    anchors.fill: parent
                    onCloseRequested: root.closeWindow()
                }

                SystemPanel {
                    visible: root.currentPage === 1
                    embedded: true
                    anchors {
                        fill: parent
                        margins: Appearance.px(8)
                    }
                    onCloseRequested: root.closeWindow()
                }

                StyleContent {
                    visible: root.currentPage === 2
                    anchors.fill: parent
                    onCloseRequested: root.closeWindow()
                }

                DisplayContent {
                    visible: root.currentPage === 3
                    anchors.fill: parent
                    onCloseRequested: root.closeWindow()
                }
            }
        }
    }
}
