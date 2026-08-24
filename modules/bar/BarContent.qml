pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "file:///home/lengineerc/.config/quickshell/lc_qs_niri/Caelestia/Blobs" as Blobs
import qs.common
import qs.services

Item {
    id: root

    implicitHeight: Appearance.barHeight
    readonly property Item barMask: barInputRegion
    readonly property Item popupMask: popup.popupMaskItem
    readonly property bool barContainsMouse: barHover.hovered
        && barHover.point.position.y >= 0
        && barHover.point.position.y < Appearance.barHeight
    readonly property bool popupShown: popup.shown
    readonly property bool popupContainsMouse: popup.pointerInside
    readonly property bool notificationPanelShown:
        popup.shown && popup.page === "notifications"
    readonly property bool sidebarShown:
        LeftSidebarService.shown
        && LeftSidebarService.targetOutputName === root.outputName
    readonly property bool hostWindowActive: Window.active
    readonly property int edgeMargin: Appearance.cornerSize

    property real effectsOpacity: 1
    readonly property real compactLevel: width <= Appearance.px(1000) ? 2
        : width <= Appearance.px(1200) ? 1 : 0
    property string outputName: ""

    function closePopup() {
        popup.close();
    }

    function closeSidebar() {
        LeftSidebarService.close();
    }

    function closeOverlays() {
        popup.close();
        LeftSidebarService.close();
    }

    function showPopup(target, pageName) {
        LeftSidebarService.close();
        popup.showFor(target, pageName);
    }

    function handleNotificationPanelAction(action, targetOutputName) {
        const targetsThisBar = targetOutputName === root.outputName;

        if (action === "close" || !targetsThisBar) {
            if (root.notificationPanelShown)
                popup.close();
            return;
        }

        if (action === "toggle" && root.notificationPanelShown) {
            popup.close();
        } else {
            NotificationService.requestPanelFocusProxy(
                root.outputName, root.hostWindowActive);
            if (!root.notificationPanelShown)
                root.showPopup(notificationModule, "notifications");
        }
    }

    function syncNotificationPanelVisibility() {
        NotificationService.updatePanelVisibility(
            root.outputName, root.notificationPanelShown);
    }

    function requestHostWindowFocus() {
        root.forceActiveFocus(Qt.MouseFocusReason);
        Window.window?.requestActivate();
    }

    onHostWindowActiveChanged:
        NotificationService.updatePanelHostFocus(
            root.outputName,
            root.notificationPanelShown && root.hostWindowActive)

    onNotificationPanelShownChanged:
        NotificationService.updatePanelHostFocus(
            root.outputName,
            root.notificationPanelShown && root.hostWindowActive)

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

    // This handler belongs to the common ancestor of every bar control, so
    // child MouseAreas cannot hide hover events from it. Limit the result to
    // the visual bar because this root also contains the popup area.
    HoverHandler {
        id: barHover
    }

    // 手动添加底色层，修复离屏纹理边缘采样导致bar未贴合屏幕
    Rectangle {
        id: solidBarBackground

        z: -3

        x: 0
        y: 0
        width: root.width
        height: Appearance.barHeight

        color: Appearance.barBgColor
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
                onClicked: root.closeOverlays()
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
            deformScale: 0.000002
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: event => {
                if (event.button === Qt.RightButton) {
                    popup.close();
                    // This Bar already knows its output. Avoid the async
                    // focused-output query, whose stale result could reopen
                    // the sidebar after a rapid close.
                    LeftSidebarService.toggleOnOutput(root.outputName);
                } else {
                    root.showPopup(launcherControl, "launcher");
                }
            }

            Rectangle {
                id: launcherPill
                width: Appearance.px(30)
                height: Appearance.px(30)
                anchors.verticalCenter: parent.verticalCenter
                radius: Appearance.fullRadius
                color: launcherControl.containsMouse
                    || popup.shown && popup.anchorItem === launcherControl
                    || root.sidebarShown
                    ? Appearance.secondaryContainer
                    : Appearance.withAlpha(
                        Appearance.secondaryContainer, 0)
                scale: launcherControl.pressed ? 0.88 : 1

                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    color: Appearance.layer0Text
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(21)
                    }
                }

                Behavior on color {
                    enabled: !Theme.paletteTransitionRunning
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
                width: Math.min(
                    400,
                    Math.max(0, focusedWindowInfo.width
                    - (focusedWindowIcon.visible
                        ? focusedWindowIcon.width + focusedWindowInfo.spacing : 0))
                )
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

        readonly property real clockCenterInRow:
            workspaceSwitcher.width + spacing
                + weatherModule.width + spacing
                + timeModule.width / 2

        x: {
            const barCenter = parent.width / 2;
            if (ShellSettings.barCenterAlignment === "clock") {
                return Math.round(barCenter - clockCenterInRow);
            }
            return Math.round(barCenter - implicitWidth / 2);
        }
        width: implicitWidth
        anchors {
            top: parent.top
        }
        height: Appearance.barHeight
        spacing: Appearance.px(4)

        WorkspaceSwitcher {
            id: workspaceSwitcher

            anchors.verticalCenter: parent.verticalCenter
            outputName: root.outputName
        }

        WeatherModule {
            id: weatherModule

            anchors.verticalCenter: parent.verticalCenter
            onActivated: root.showPopup(weatherModule, "weather")
        }

        TimeModule {
            id: timeModule

            showDate: root.compactLevel < 2
            anchors.verticalCenter: parent.verticalCenter
            onActivated: root.showPopup(timeModule, "calendar")
        }

        MediaModule {
            id: mediaModule

            compact: root.compactLevel > 0
            visible: root.compactLevel < 2
            anchors.verticalCenter: parent.verticalCenter
            onActivated: root.showPopup(mediaModule, "media")
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
            onActivated: root.showPopup(batteryModule, "battery")
        }

        PerformanceModule {
            id: performanceModule

            anchors {
                right: batteryModule.left
                rightMargin: Appearance.px(4)
                verticalCenter: parent.verticalCenter
            }
            onActivated:
                root.showPopup(performanceModule, "resources")
        }

        SystemModule {
            id: systemModule

            compact: root.compactLevel > 0
            anchors {
                right: powerModule.left
                rightMargin: Appearance.px(4)
            }
            
            onActivated: root.showPopup(systemModule, "system")
        }

        PowerModule {
            id: powerModule

            anchors {
                right: parent.right
                rightMargin: root.edgeMargin
                verticalCenter: parent.verticalCenter
            }
            onActivated: root.showPopup(powerModule, "power")
        }

        ClipboardModule {
            id: clipboardModule

            anchors {
                right: settingsControl.left
                rightMargin: Appearance.px(4)
                verticalCenter: parent.verticalCenter
            }
            onActivated: root.showPopup(clipboardModule, "clipboard")
        }

        NotificationModule {
            id: notificationModule

            anchors {
                right: clipboardModule.left
                rightMargin: Appearance.px(3)
                verticalCenter: parent.verticalCenter
            }
            onActivated:
                root.showPopup(notificationModule, "notifications")
        }

        Connections {
            target: NotificationService

            function onPanelActionRequested(action, outputName) {
                root.handleNotificationPanelAction(action, outputName);
            }
        }

        TrayModule {
            id: trayModule

            expanded: popup.shown
                && popup.anchorItem === trayModule
                && popup.page === "tray"
            anchors {
                right: notificationModule.left
                rightMargin: Appearance.px(3)
                verticalCenter: parent.verticalCenter
            }
            onActivated:
                root.showPopup(trayModule, "tray")
        }

        MouseArea {
            id: settingsControl

            anchors {
                right: performanceModule.left
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
                    ? Appearance.layer1Hover
                    : Appearance.withAlpha(Appearance.layer1Hover, 0)
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
                    enabled: !Theme.paletteTransitionRunning
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
        outputName: root.outputName
        deformMatrix: popupBackground.deformMatrix
    }

    Connections {
        target: popup

        function onShownChanged() {
            root.syncNotificationPanelVisibility();
        }

        function onPageChanged() {
            root.syncNotificationPanelVisibility();
        }
    }

}
