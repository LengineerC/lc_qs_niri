pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.common
import qs.services

Item {
    id: root

    property string outputName: ""
    readonly property bool compact: height < Appearance.px(1000)
    readonly property real groupSpacing: Appearance.spacingTiny
    readonly property real edgeMargin: Appearance.cornerSize
    readonly property real middleAvailableHeight: Math.max(0,
        bottomGroup.y - topGroup.height - root.edgeMargin - root.groupSpacing * 2)
    readonly property real middleHeight: Math.min(middleContents.implicitHeight, middleAvailableHeight)
    readonly property real desiredMiddleY: ShellSettings.barCenterAlignment === "clock"
        ? height / 2 - (verticalClock.y + verticalClock.height / 2)
        : (height - middleContents.implicitHeight) / 2
    readonly property real textLineHeight: Appearance.px(14)
    readonly property real topMaximumHeight: Math.max(Appearance.px(30)
        + (focusedWindowIcon.visible ? focusedWindowIcon.height : 0)
        + root.groupSpacing * 2 + root.textLineHeight * 2,
        Math.min(root.desiredMiddleY, bottomGroup.y - middleContents.implicitHeight - root.groupSpacing)
            - root.edgeMargin - root.groupSpacing)
    readonly property int windowTextCapacity: Math.max(2, Math.floor(
        (topMaximumHeight - Appearance.px(30)
            - (focusedWindowIcon.visible ? focusedWindowIcon.height : 0)
            - root.groupSpacing * 2) / textLineHeight))
    property bool launcherExpanded: false
    readonly property Item launcherAnchor: launcher
    signal sidebarRequested
    property bool trayExpanded: false
    readonly property Item notificationAnchor: notificationModule
    readonly property var activeWindow: NiriService.activeWindowForOutput(outputName)
    signal popupRequested(Item target, string page)

    function closeContextMenu() { trayModule.closeContextMenu(); }
    function verticalText(value, limit) {
        const text = Array.from(String(value || ""));
        return text.length > limit
            ? text.slice(0, limit - 1).join("\n") + "\n…"
            : text.join("\n");
    }

    // Left/middle/right become top/middle/bottom. Each group scrolls only
    // when it cannot fit, so many pinned tray icons cannot displace the clock.
    Flickable {
        id: topGroup
        y: root.edgeMargin
        width: parent.width
        height: Math.min(topContents.implicitHeight, root.topMaximumHeight)
        contentWidth: width
        contentHeight: topContents.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        Column {
            id: topContents
            width: parent.width
            spacing: root.groupSpacing
            LauncherButton {
                id: launcher
                anchors.horizontalCenter: parent.horizontalCenter
                width: Appearance.px(30)
                height: Appearance.px(30)
                active: root.launcherExpanded
                    || LeftSidebarService.shown && LeftSidebarService.targetOutputName === root.outputName
                onActivated: root.popupRequested(launcher, "launcher")
                onSidebarRequested: root.sidebarRequested()
            }

            Image {
                id: focusedWindowIcon
                anchors.horizontalCenter: parent.horizontalCenter
                width: Appearance.px(20)
                height: visible ? width : 0
                visible: ShellSettings.showActiveWindowIcon && source !== ""
                source: root.activeWindow?.iconSource ?? ""
                sourceSize.width: width
                sourceSize.height: height
                smooth: true
                opacity: ShellSettings.monochromeAppIconsActive ? Appearance.monochromeAppIconOpacity : 1
                layer.enabled: ShellSettings.monochromeAppIconsActive
                layer.effect: MultiEffect { saturation: -1; brightness: 0.12; contrast: 0.08 }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Appearance.px(2)
                AppText {
                    text: root.verticalText(root.activeWindow?.appId || I18n.tr("desktop"), root.windowTextCapacity)
                    color: Appearance.barSubtext
                    horizontalAlignment: Text.AlignHCenter
                    lineHeightMode: Text.FixedHeight
                    lineHeight: root.textLineHeight
                    font.pixelSize: Appearance.px(10)
                }
                AppText {
                    text: root.verticalText(root.activeWindow?.title || I18n.tr("noFocusedWindow"), root.windowTextCapacity)
                    color: Appearance.barLayer0Text
                    horizontalAlignment: Text.AlignHCenter
                    lineHeightMode: Text.FixedHeight
                    lineHeight: root.textLineHeight
                    font.pixelSize: Appearance.px(11)
                }
            }

        }
    }

    Flickable {
        id: middleGroup
        y: Math.max(topGroup.y + topGroup.height + root.groupSpacing,
            Math.min(root.desiredMiddleY, bottomGroup.y - root.groupSpacing - height))
        width: parent.width
        height: root.middleHeight
        contentWidth: width
        contentHeight: middleContents.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        Column {
            id: middleContents
            width: parent.width
            spacing: root.groupSpacing
            Item {
                width: parent.width
                height: workspaces.implicitWidth
                WorkspaceSwitcher {
                    id: workspaces
                    outputName: root.outputName
                    verticalPresentation: true
                    anchors.centerIn: parent
                    rotation: 90
                    width: implicitWidth
                    height: Appearance.barHeight
                }
            }
            WeatherModule {
                vertical: true
                onActivated: root.popupRequested(this, "weather")
            }
            TimeModule {
                id: verticalClock
                vertical: true
                onActivated: root.popupRequested(this, "calendar")
            }
            MediaModule {
                vertical: true
                verticalTextLimit: root.compact ? 4 : 6
                visible: MediaService.available
                onActivated: root.popupRequested(this, "media")
            }
        }
    }

    Item {
        id: bottomGroup
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.edgeMargin
        width: parent.width
        height: Math.min(bottomContents.implicitHeight + Appearance.px(30) + root.groupSpacing,
            root.height * 0.45)
        Flickable {
            width: parent.width
            height: Math.max(0, parent.height - Appearance.px(30) - root.groupSpacing)
            contentWidth: width
            contentHeight: bottomContents.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            Column {
                id: bottomContents
                width: parent.width
                spacing: root.groupSpacing
                TrayModule {
                    id: trayModule
                    vertical: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    expanded: root.trayExpanded
                    onActivated: root.popupRequested(this, "tray")
                    onCloseRequested: root.popupRequested(this, "tray")
                }
                NotificationModule {
                    id: notificationModule
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: Appearance.px(30)
                    onActivated: root.popupRequested(this, "notifications")
                }
                ClipboardModule {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: Appearance.px(30)
                    onActivated: root.popupRequested(this, "clipboard")
                }
                MouseArea {
                    width: parent.width
                    height: Appearance.px(30)
                    hoverEnabled: true
                    onClicked: {
                        root.closeContextMenu();
                        SettingsLauncher.open();
                    }
                    AppText {
                        anchors.centerIn: parent
                        text: "󰒓"
                        color: Appearance.barLayer0Text
                        font.family: Appearance.iconFontFamily
                        font.pixelSize: Appearance.px(17)
                    }
                }
                PerformanceModule {
                    vertical: true
                    onActivated: root.popupRequested(this, "resources")
                }
                BatteryModule {
                    vertical: true
                    onActivated: root.popupRequested(this, "battery")
                }
                SystemModule {
                    vertical: true
                    onActivated: root.popupRequested(this, "system")
                }
            }
        }
        PowerModule {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            height: Appearance.px(30)
            onActivated: root.popupRequested(this, "power")
        }
    }
}
