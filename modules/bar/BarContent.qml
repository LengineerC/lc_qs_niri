pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "file:///home/lengineerc/.config/quickshell/lc_qs_niri/Caelestia/Blobs" as Blobs
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    implicitHeight: Appearance.barHeight
    readonly property Item barMask: barInputRegion
    readonly property Item leftCornerBlurBounds: leftConnectorBlurBounds
    readonly property Item leftCornerBlurCutout: leftConnectorBlurCutout
    readonly property Item rightCornerBlurBounds: rightConnectorBlurBounds
    readonly property Item rightCornerBlurCutout: rightConnectorBlurCutout
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
    readonly property int connectorTop:
        Appearance.barHeight - Appearance.px(1)

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

    component BarText: AppText {
        color: Appearance.barLayer1Text
        verticalAlignment: Text.AlignVCenter
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component BarIcon: AppText {
        color: Appearance.barSecondaryContainerText
        verticalAlignment: Text.AlignVCenter
        font {
            family: Appearance.iconFontFamily
            weight: Font.Normal
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

    // Geometry used to construct the two concave connector blur regions.
    // These items never receive input or draw pixels.
    Item {
        id: leftConnectorBlurBounds

        x: 0
        y: root.connectorTop
        width: Appearance.cornerSize
        height: Appearance.cornerSize
    }

    Item {
        id: leftConnectorBlurCutout

        x: 0
        y: root.connectorTop
        width: Appearance.cornerSize * 2
        height: Appearance.cornerSize * 2
    }

    Item {
        id: rightConnectorBlurBounds

        x: root.width - Appearance.cornerSize
        y: root.connectorTop
        width: Appearance.cornerSize
        height: Appearance.cornerSize
    }

    Item {
        id: rightConnectorBlurCutout

        x: root.width - Appearance.cornerSize * 2
        y: root.connectorTop
        width: Appearance.cornerSize * 2
        height: Appearance.cornerSize * 2
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

        // The Blob surface below is sufficient in glass mode. Keeping this
        // fallback visible would stack two tints and make the bar opaque.
        color: Appearance.barBgColor
        opacity: ShellSettings.barFrostedGlass ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: Appearance.fastDuration }
        }
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
        // Apply opacity to the rendered Blob layer itself. The native Blob
        // material does not otherwise give us a separate tint-opacity stage.
        opacity: ShellSettings.barFrostedGlass
            ? Appearance.barGlassTintOpacity : 1
        // The Bar and popup share one Blob layer, so the shadow follows their
        // combined outline instead of being drawn between the two surfaces.
        layer.enabled: ShellSettings.shadowEnabled
            && root.effectsOpacity > 0.001
        layer.effect: MultiEffect {
            shadowEnabled: ShellSettings.shadowEnabled
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Appearance.barShadow,
                ShellSettings.shadowOpacity
                    * Math.max(0, Math.min(1, root.effectsOpacity)))
            shadowVerticalOffset: Math.round(
                ShellSettings.shadowOffsetY * Appearance.scale)
        }

        Blobs.BlobGroup {
            id: barBlobGroup

            color: Appearance.barSurfaceBaseColor
            smoothing: Appearance.px(20)
        }

        Behavior on opacity {
            NumberAnimation { duration: Appearance.fastDuration }
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

            // The old 20% overlap could reach more than 100 px into the Bar
            // for tall panels. That is invisible with an opaque fill but
            // becomes a clearly brighter double layer with glass. A tiny
            // overlap is enough for BlobGroup to keep one continuous shape.
            readonly property real overlapHeight:
                ShellSettings.barFrostedGlass
                    ? Appearance.px(2) : popup.height * 0.2

            visible: popup.revealProgress > 0
            group: barBlobGroup
            x: popup.x
            y: Appearance.barHeight - overlapHeight
            width: visible ? popup.width : 0
            height: visible
                ? popup.height + overlapHeight : 0
            radius: Appearance.normalRadius
            deformScale: 0.000002
        }

        // In glass mode the connector corners must be captured by the same
        // layer as the Bar. Parent opacity and the shadow are then applied
        // once to the combined silhouette, avoiding a second blend over the
        // shadow beneath the Bar edge.
        RoundCorner {
            x: 0
            y: root.connectorTop
            visible: ShellSettings.barFrostedGlass
            implicitSize: Appearance.cornerSize
            layerEnabled: false
            color: Appearance.barSurfaceBaseColor
            corner: RoundCorner.CornerEnum.TopLeft
        }

        RoundCorner {
            x: parent.width - width
            y: root.connectorTop
            visible: ShellSettings.barFrostedGlass
            implicitSize: Appearance.cornerSize
            layerEnabled: false
            color: Appearance.barSurfaceBaseColor
            corner: RoundCorner.CornerEnum.TopRight
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
                    ? Appearance.barSecondaryContainer
                    : Appearance.withAlpha(
                        Appearance.barSecondaryContainer, 0)
                scale: launcherControl.pressed ? 0.88 : 1

                AppText {
                    anchors.centerIn: parent
                    text: "✦"
                    color: Appearance.barLayer0Text
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
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
                opacity: ShellSettings.monochromeAppIconsActive
                    ? Appearance.monochromeAppIconOpacity : 1
                layer.enabled: ShellSettings.monochromeAppIconsActive
                layer.effect: MultiEffect {
                    saturation: -1
                    brightness: 0.12
                    contrast: 0.08
                }
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

                AppText {
                    width: parent.width
                    text: NiriService.focusedWindow?.appId
                        ?? I18n.tr("desktop")
                    color: Appearance.barSubtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                AppText {
                    width: parent.width
                    text: NiriService.focusedWindow?.title
                        ?? I18n.tr("noFocusedWindow")
                    color: Appearance.barLayer0Text
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
                    ? Appearance.barLayer1Hover
                    : Appearance.withAlpha(Appearance.barLayer1Hover, 0)
                scale: settingsControl.pressed ? 0.88 : 1

                AppText {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: Appearance.barLayer0Text
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
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
