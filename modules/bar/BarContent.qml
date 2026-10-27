pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    readonly property bool vertical: ShellSettings.barVertical
    readonly property string edge: ShellSettings.barPosition
    readonly property real surfaceWidth: vertical ? height : width
    readonly property real surfaceHeight: vertical ? width : height
    readonly property real surfaceRotation: edge === "bottom" ? 180 : edge === "left" ? -90 : edge === "right" ? 90 : 0
    readonly property real surfaceX: edge === "bottom" || edge === "right" ? width : 0
    readonly property real surfaceY: edge === "bottom" || edge === "left" ? height : 0
    readonly property real barX: edge === "right" ? width - Appearance.barHeight : 0
    readonly property real barY: edge === "bottom" ? height - Appearance.barHeight : 0
    implicitHeight: Appearance.barHeight
    readonly property Item barMask: barInputRegion
    readonly property Item leftCornerBlurBounds: leftConnectorBlurBounds
    readonly property Item leftCornerBlurCutout: leftConnectorBlurCutout
    readonly property Item rightCornerBlurBounds: rightConnectorBlurBounds
    readonly property Item rightCornerBlurCutout: rightConnectorBlurCutout
    readonly property Item popupMask: popup.popupMaskItem
    readonly property bool barContainsMouse: barHover.hovered && (vertical ? barHover.point.position.x >= barX && barHover.point.position.x < barX + Appearance.barHeight : barHover.point.position.y >= barY && barHover.point.position.y < barY + Appearance.barHeight)
    readonly property bool popupShown: popup.shown
    readonly property bool popupContainsMouse: popup.pointerInside
    readonly property bool notificationPanelShown: popup.shown && popup.page === "notifications"
    readonly property bool sidebarShown: LeftSidebarService.shown && LeftSidebarService.targetOutputName === root.outputName
    readonly property bool hostWindowActive: Window.active
    readonly property var outputActiveWindow:
        NiriService.activeWindowForOutput(outputName)
    readonly property int edgeMargin: Appearance.cornerSize
    readonly property int connectorTop: Appearance.barHeight - Appearance.px(1)

    property real effectsOpacity: 1
    readonly property real compactLevel: width <= Appearance.px(1000) ? 2 : width <= Appearance.px(1200) ? 1 : 0
    property string outputName: ""

    function closePopup() {
        popup.close();
    }

    function closeSidebar() {
        LeftSidebarService.close();
    }

    function closeOverlays() {
        popup.close();
        trayModule.closeContextMenu();
        verticalContent.closeContextMenu();
        LeftSidebarService.close();
    }

    function showPopup(target, pageName) {
        trayModule.closeContextMenu();
        verticalContent.closeContextMenu();
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
            NotificationService.requestPanelFocusProxy(root.outputName, root.hostWindowActive);
            if (!root.notificationPanelShown)
                root.showPopup(root.vertical ? verticalContent.notificationAnchor : notificationModule, "notifications");
        }
    }

    function syncNotificationPanelVisibility() {
        NotificationService.updatePanelVisibility(root.outputName, root.notificationPanelShown);
    }

    function requestHostWindowFocus() {
        root.forceActiveFocus(Qt.MouseFocusReason);
        Window.window?.requestActivate();
    }

    onHostWindowActiveChanged: NotificationService.updatePanelHostFocus(root.outputName, root.notificationPanelShown && root.hostWindowActive)

    onNotificationPanelShownChanged: NotificationService.updatePanelHostFocus(root.outputName, root.notificationPanelShown && root.hostWindowActive)

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

        x: root.barX
        y: root.barY
        width: root.vertical ? Appearance.barHeight : root.width
        height: root.vertical ? root.height : Appearance.barHeight
    }

    Item {
        x: root.surfaceX
        y: root.surfaceY
        width: root.surfaceWidth
        height: root.surfaceHeight
        rotation: root.surfaceRotation
        transformOrigin: Item.TopLeft

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

            x: root.surfaceWidth - Appearance.cornerSize
            y: root.connectorTop
            width: Appearance.cornerSize
            height: Appearance.cornerSize
        }

        Item {
            id: rightConnectorBlurCutout

            x: root.surfaceWidth - Appearance.cornerSize * 2
            y: root.connectorTop
            width: Appearance.cornerSize * 2
            height: Appearance.cornerSize * 2
        }

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

        x: root.barX
        y: root.barY
        width: root.vertical ? Appearance.barHeight : root.width
        height: root.vertical ? root.height : Appearance.barHeight

        // The Blob surface below is sufficient in glass mode. Keeping this
        // fallback visible would stack two tints and make the bar opaque.
        color: Appearance.barBgColor
        opacity: ShellSettings.barFrostedGlass ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.fastDuration
            }
        }
    }

    Item {
        id: shadowSurface

        z: -2
        readonly property real normalExtent: Math.min(root.vertical ? root.width : root.height,
            Appearance.barHeight + (root.vertical ? popup.width : popup.height)
            + Math.max(Appearance.cornerSize, Math.ceil((ShellSettings.shadowBlurRadius
                + Math.abs(ShellSettings.shadowOffsetY) + 4) * Appearance.scale)))
        x: root.edge === "right" ? root.width - normalExtent : 0
        y: root.edge === "bottom" ? root.height - normalExtent : 0
        width: root.vertical ? normalExtent : root.width
        height: root.vertical ? root.height : normalExtent
        // Apply opacity to the rendered Blob layer itself. The native Blob
        // material does not otherwise give us a separate tint-opacity stage.
        opacity: ShellSettings.barFrostedGlass ? Appearance.barGlassTintOpacity : 1
        // The Bar and popup share one Blob layer, so the shadow follows their
        // combined outline instead of being drawn between the two surfaces.
        layer.enabled: ShellSettings.shadowEnabled && root.effectsOpacity > 0.001
        layer.effect: MultiEffect {
            shadowEnabled: ShellSettings.shadowEnabled
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(Appearance.barShadow, ShellSettings.shadowOpacity * Math.max(0, Math.min(1, root.effectsOpacity)))
            shadowHorizontalOffset: root.vertical
                ? Math.round(ShellSettings.shadowOffsetY * Appearance.scale) * (root.edge === "left" ? 1 : -1) : 0
            shadowVerticalOffset: root.vertical ? 0
                : Math.round(ShellSettings.shadowOffsetY * Appearance.scale) * (root.edge === "bottom" ? -1 : 1)
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.fastDuration
            }
        }

        Loader {
            id: blobSurface

            anchors.fill: parent
            // Native plugins need a real file URL, not Quickshell's qs: VFS.
            // Encode each segment so spaces, # and non-ASCII paths also work.
            source: "file://" + Quickshell.shellPath(
                "native/caelestia-blobs/BarBlobSurface.qml")
                .split("/").map(encodeURIComponent).join("/")
            asynchronous: false

            readonly property color surfaceColor: Appearance.barSurfaceBaseColor
            readonly property real smoothing: Appearance.px(20)
            readonly property string edge: root.edge
            readonly property real barX: root.barX - shadowSurface.x
            readonly property real barY: root.barY - shadowSurface.y
            readonly property real barWidth: root.vertical ? Appearance.barHeight : root.width
            readonly property real barHeight: root.vertical ? root.height : Appearance.barHeight
            readonly property bool popupVisible: popup.revealProgress > 0
            readonly property real popupX: popup.x - shadowSurface.x
            readonly property real popupY: popup.y - shadowSurface.y
            readonly property real popupWidth: popup.width
            readonly property real popupHeight: popup.height
            readonly property real popupRadius: Appearance.normalRadius
            readonly property real overlapHeight: ShellSettings.barFrostedGlass
                ? Appearance.px(2) : (root.vertical ? popup.width : popup.height) * 0.2

            Connections {
                target: blobSurface.item
                function onBackgroundClicked() { root.closeOverlays(); }
            }
        }

        Item {
            x: root.surfaceX - shadowSurface.x
            y: root.surfaceY - shadowSurface.y
            width: root.surfaceWidth
            height: root.surfaceHeight
            rotation: root.surfaceRotation
            transformOrigin: Item.TopLeft
            // In glass mode the connector corners must be captured by the same
            // layer as the Bar. Parent opacity and the shadow are then applied
            // once to the combined silhouette, avoiding a second blend over the
            // shadow beneath the Bar edge.
            RoundCorner {
                x: 0
                y: root.connectorTop
                visible: ShellSettings.screenCornersEnabled && ShellSettings.barFrostedGlass
                implicitSize: Appearance.cornerSize
                layerEnabled: false
                color: Appearance.barSurfaceBaseColor
                corner: RoundCorner.CornerEnum.TopLeft
            }

            RoundCorner {
                x: parent.width - width
                y: root.connectorTop
                visible: ShellSettings.screenCornersEnabled && ShellSettings.barFrostedGlass
                implicitSize: Appearance.cornerSize
                layerEnabled: false
                color: Appearance.barSurfaceBaseColor
                corner: RoundCorner.CornerEnum.TopRight
            }
        }
    }

    Item {
        id: leftArea
        visible: !root.vertical
        y: root.barY
        anchors {
            left: parent.left
            right: middleSection.left
        }
        height: Appearance.barHeight

        LauncherButton {
            id: launcherControl
            x: root.edgeMargin
            width: Appearance.px(30)
            height: parent.height
            active: popup.shown && popup.anchorItem === launcherControl || root.sidebarShown
            onActivated: root.showPopup(launcherControl, "launcher")
            onSidebarRequested: {
                popup.close();
                LeftSidebarService.toggleOnOutput(root.outputName);
            }
        }

        Row {
            id: focusedWindowInfo

            visible: width >= Appearance.px(110)
            height: parent.height
            spacing: Appearance.spacingSmall
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
                source: root.outputActiveWindow?.iconSource ?? ""
                sourceSize.width: Appearance.px(20)
                sourceSize.height: Appearance.px(20)
                smooth: true
                visible: ShellSettings.showActiveWindowIcon && source !== ""
                opacity: ShellSettings.monochromeAppIconsActive ? Appearance.monochromeAppIconOpacity : 1
                layer.enabled: ShellSettings.monochromeAppIconsActive
                layer.effect: MultiEffect {
                    saturation: -1
                    brightness: 0.12
                    contrast: 0.08
                }
            }

            Column {
                width: Math.min(400, Math.max(0, focusedWindowInfo.width - (focusedWindowIcon.visible ? focusedWindowIcon.width + focusedWindowInfo.spacing : 0)))
                anchors {
                    verticalCenter: parent.verticalCenter
                }
                spacing: -Appearance.px(2)

                AppText {
                    width: parent.width
                    text: root.outputActiveWindow?.appId
                        || I18n.tr("desktop")
                    color: Appearance.barSubtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                AppText {
                    width: parent.width
                    text: root.outputActiveWindow?.title
                        || I18n.tr("noFocusedWindow")
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
        visible: !root.vertical
        y: root.barY

        readonly property real clockCenterInRow: workspaceSwitcher.width + spacing + weatherModule.width + spacing + timeModule.width / 2

        x: {
            const barCenter = parent.width / 2;
            if (ShellSettings.barCenterAlignment === "clock") {
                return Math.round(barCenter - clockCenterInRow);
            }
            return Math.round(barCenter - implicitWidth / 2);
        }
        width: implicitWidth
        height: Appearance.barHeight
        spacing: Appearance.spacingTiny

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
        visible: !root.vertical
        y: root.barY
        anchors {
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
            onActivated: root.showPopup(performanceModule, "resources")
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
            onActivated: root.showPopup(root.vertical ? verticalContent.notificationAnchor : notificationModule, "notifications")
        }

        Connections {
            target: NotificationService

            function onPanelActionRequested(action, outputName) {
                root.handleNotificationPanelAction(action, outputName);
            }
        }

        TrayModule {
            id: trayModule

            expanded: popup.shown && popup.anchorItem === trayModule && popup.page === "tray"
            anchors {
                right: notificationModule.left
                rightMargin: Appearance.px(3)
                verticalCenter: parent.verticalCenter
            }
            onActivated: root.showPopup(trayModule, "tray")
            onCloseRequested: popup.close()
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
            onClicked: {
                trayModule.closeContextMenu();
        verticalContent.closeContextMenu();
                SettingsLauncher.open();
            }

            Rectangle {
                width: Appearance.px(30)
                height: Appearance.px(30)
                anchors.verticalCenter: parent.verticalCenter
                radius: Appearance.fullRadius
                color: settingsControl.containsMouse ? Appearance.barLayer1Hover : Appearance.withAlpha(Appearance.barLayer1Hover, 0)
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

    VerticalBarContent {
        id: verticalContent
        visible: root.vertical
        x: root.barX
        width: Appearance.barHeight
        height: root.height
        outputName: root.outputName
        launcherExpanded: popup.shown && popup.anchorItem === verticalContent.launcherAnchor
        trayExpanded: popup.shown && popup.page === "tray"
        onPopupRequested: (target, page) => root.showPopup(target, page)
        onSidebarRequested: {
            popup.close();
            LeftSidebarService.toggleOnOutput(root.outputName);
        }
    }

    Connections {
        target: ShellSettings
        function onBarPositionChanged() { root.closeOverlays(); }
    }

    StyledPopup {
        id: popup
        z: 10
        outputName: root.outputName
        deformMatrix: blobSurface.item?.deformMatrix ?? Qt.matrix4x4()
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
