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
    color: SettingsPalette.glassMode
        ? "transparent" : SettingsPalette.layer0
    width: Math.min(screen?.width * 0.86 ?? Appearance.px(980),
        Appearance.px(980))
    height: Math.min(screen?.height * 0.92 ?? Appearance.px(920),
        Appearance.px(920))
    minimumWidth: Appearance.px(760)
    minimumHeight: Appearance.px(620)

    readonly property Component currentPageComponent: {
        switch (currentPage) {
        case 1: return systemPageComponent;
        case 2: return stylePageComponent;
        case 3: return displayPageComponent;
        default: return settingsPageComponent;
        }
    }

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

    Component {
        id: settingsPageComponent

        SettingsContent {
            anchors.fill: parent
            onCloseRequested: root.closeWindow()
        }
    }

    Component {
        id: systemPageComponent

        SystemPanel {
            embedded: true
            anchors.fill: parent
            onCloseRequested: root.closeWindow()
        }
    }

    Component {
        id: stylePageComponent

        StyleContent {
            anchors.fill: parent
            onCloseRequested: root.closeWindow()
        }
    }

    Component {
        id: displayPageComponent

        DisplayContent {
            anchors.fill: parent
            onCloseRequested: root.closeWindow()
        }
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

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: SettingsPalette.window

        Rectangle {
            anchors.fill: parent
            visible: SettingsPalette.glassMode
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: SettingsPalette.windowSheen
                }
                GradientStop {
                    position: 0.32
                    color: Appearance.withAlpha("#ffffff", 0.018)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }

        RowLayout {
            anchors {
                fill: parent
                margins: Appearance.spacingMedium
            }
            spacing: Appearance.spacingMedium

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Appearance.px(
                    I18n.language === "en_US" ? 210 : 190)
                radius: Appearance.normalRadius
                color: SettingsPalette.layer1
                border.width: 1
                border.color: SettingsPalette.layer0Border

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Appearance.panelPadding
                    }
                    spacing: Appearance.spacingMedium

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Appearance.px(12)
                        spacing: Appearance.spacingMedium

                        Rectangle {
                            implicitWidth: Appearance.px(42)
                            implicitHeight: Appearance.largeControlHeight
                            radius: Appearance.cardRadius
                            color: SettingsPalette.primaryContainer

                            AppText {
                                anchors.centerIn: parent
                                text: "󰣇"
                                color: SettingsPalette.primaryContainerText
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(24)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            AppText {
                                text: "QuickShell"
                                color: SettingsPalette.layer0Text
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.largeFontSize
                                    weight: Font.DemiBold
                                }
                            }

                            AppText {
                                text: I18n.tr("settings")
                                color: SettingsPalette.subtext
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
                        implicitHeight: Appearance.largeControlHeight
                        radius: Appearance.cardRadius
                        color: root.currentPage === 0
                            ? SettingsPalette.secondaryContainer
                            : quickSettingsMouse.containsMouse
                                ? SettingsPalette.layer1Hover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Appearance.fastDuration }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.spacingMedium

                            AppText {
                                text: "󰒓"
                                color: root.currentPage === 0
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            AppText {
                                Layout.fillWidth: true
                                text: I18n.tr("quickSettings")
                                color: root.currentPage === 0
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
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
                        implicitHeight: Appearance.largeControlHeight
                        radius: Appearance.cardRadius
                        color: root.currentPage === 1
                            ? SettingsPalette.secondaryContainer
                            : networkMouse.containsMouse
                                ? SettingsPalette.layer1Hover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Appearance.fastDuration }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.spacingMedium

                            AppText {
                                text: "󰛳"
                                color: root.currentPage === 1
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            AppText {
                                Layout.fillWidth: true
                                text: I18n.tr("networkDevices")
                                color: root.currentPage === 1
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
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
                        implicitHeight: Appearance.largeControlHeight
                        radius: Appearance.cardRadius
                        color: root.currentPage === 3
                            ? SettingsPalette.secondaryContainer
                            : displaysMouse.containsMouse
                                ? SettingsPalette.layer1Hover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Appearance.fastDuration }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.spacingMedium

                            AppText {
                                text: "󰍹"
                                color: root.currentPage === 3
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            AppText {
                                Layout.fillWidth: true
                                text: I18n.tr("displays")
                                color: root.currentPage === 3
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
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
                        implicitHeight: Appearance.largeControlHeight
                        radius: Appearance.cardRadius
                        color: root.currentPage === 2
                            ? SettingsPalette.secondaryContainer
                            : styleMouse.containsMouse
                                ? SettingsPalette.layer1Hover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Appearance.fastDuration }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(12)
                            }
                            spacing: Appearance.spacingMedium

                            AppText {
                                text: "󰏘"
                                color: root.currentPage === 2
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(18)
                                }
                            }

                            AppText {
                                Layout.fillWidth: true
                                text: I18n.tr("style")
                                color: root.currentPage === 2
                                    ? SettingsPalette.secondaryContainerText
                                    : SettingsPalette.layer1Text
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
                color: SettingsPalette.layer2
                border.width: 1
                border.color: SettingsPalette.layer0Border
                clip: true

                Loader {
                    anchors.fill: parent
                    active: root.visible
                    asynchronous: false
                    sourceComponent: root.currentPageComponent
                }
            }
        }
    }
}
