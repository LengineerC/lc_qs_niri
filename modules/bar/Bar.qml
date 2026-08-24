pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.common.widgets
import qs.modules.sidebar
import qs.services

Scope {
    component BarConnectorCorner: Item {
        id: connectorCorner

        required property var corner
        property real effectsOpacity: 1

        implicitWidth: Appearance.cornerSize
        implicitHeight: Appearance.cornerSize
        clip: true

        MultiEffect {
            anchors.fill: cornerFill
            z: 0
            visible: ShellSettings.shadowEnabled
            source: cornerFill
            shadowEnabled: true
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Theme.palette.m3shadow,
                ShellSettings.shadowOpacity
                    * Math.max(0, Math.min(1,
                        connectorCorner.effectsOpacity)))
            shadowHorizontalOffset: 0
            shadowVerticalOffset: Math.round(
                ShellSettings.shadowOffsetY * Appearance.scale)
            autoPaddingEnabled: true
        }

        RoundCorner {
            id: cornerFill

            anchors.fill: parent
            z: 1
            implicitSize: Appearance.cornerSize
            color: Appearance.barBgColor
            corner: connectorCorner.corner
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow

            required property ShellScreen modelData
            // Hide only the bar body. The lower corner pair then stops at the
            // screen edge instead of moving out of view with the bar.
            readonly property real hiddenOffset: -Appearance.barHeight

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: modelData.height
            // Keep the layer-shell geometry stable while overview animates.
            // Resizing the exclusive zone mid-animation can expose an
            // unpainted compositor frame.
            exclusiveZone: Appearance.barHeight
            exclusionMode: ExclusionMode.Normal
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:bar"
            WlrLayershell.keyboardFocus:
                    NiriService.overviewProgress <= 0
                    && (barContent.popupShown
                        || barContent.barContainsMouse)
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Region {
                id: normalMask

                Region {
                    // Keep the bar hit region in window coordinates. Using an
                    // item below the animated barSurface can leave the
                    // layer-shell input region at its overview offset.
                    x: 0
                    y: 0
                    width: barWindow.width
                    height: Appearance.barHeight
                }
                Region {
                    item: barContent.popupMask
                }
            }

            Region {
                id: overviewMask
            }

            MouseArea {
                anchors.fill: parent
                onClicked: forceActiveFocus()
            }

            // Do not disable the whole Qt Quick subtree during overview.
            // Swap the Wayland input region instead, then restore a fresh,
            // fixed-coordinate mask after the slide-in animation completes.
            mask: NiriService.overviewProgress > 0
                ? overviewMask : normalMask

            Timer {
                id: focusDismissTimer

                interval: 120
                onTriggered: {
                    if (barContent.popupShown
                            && !barContent.hostWindowActive
                            && !barContent.popupContainsMouse
                            && NotificationService
                                .panelFocusProxyOutputName
                                !== barWindow.modelData.name) {
                        barContent.closePopup();
                    }
                }
            }

            Connections {
                target: barContent

                function onPopupShownChanged() {
                    if (!barContent.popupShown) {
                        focusDismissTimer.stop();
                        return;
                    }

                    // The hover binding above lets Niri focus this surface
                    // on the opening click. Also request activation after
                    // bindings have settled for keyboard/touch activation.
                    focusDismissTimer.stop();
                    if (NotificationService.panelFocusProxyOutputName
                            === barWindow.modelData.name) {
                        return;
                    }
                    barContent.requestHostWindowFocus();
                    Qt.callLater(
                        () => barContent.requestHostWindowFocus());
                }

                function onHostWindowActiveChanged() {
                    if (barContent.hostWindowActive) {
                        focusDismissTimer.stop();
                    } else if (barContent.popupShown
                            && NotificationService
                                .panelFocusProxyOutputName
                                !== barWindow.modelData.name) {
                        focusDismissTimer.restart();
                    }
                }

                function onPopupContainsMouseChanged() {
                    if (barContent.popupContainsMouse) {
                        focusDismissTimer.stop();
                    } else if (barContent.popupShown
                            && !barContent.hostWindowActive
                            && NotificationService
                                .panelFocusProxyOutputName
                                !== barWindow.modelData.name) {
                        focusDismissTimer.restart();
                    }
                }
            }

            Item {
                id: barSurface

                width: parent.width
                // The popup is a descendant of this item. Keep its whole
                // ancestor chain large enough for Qt Quick to route pointer
                // events to content drawn below the bar.
                height: parent.height
                y: barWindow.hiddenOffset * NiriService.overviewProgress

                BarContent {
                    id: barContent

                    outputName: modelData.name
                    effectsOpacity: 1 - NiriService.overviewProgress
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                }

                Item {
                    // Keep connector shadows behind BarContent so they cannot
                    // spill over an open panel. The visible corner fill is
                    // drawn again in the foreground strip below.
                    z: -1
                    x: 0
                    y: Appearance.barHeight - 1
                    width: parent.width
                    height: Appearance.cornerSize

                    BarConnectorCorner {
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                        corner: RoundCorner.CornerEnum.TopLeft
                        effectsOpacity: barContent.effectsOpacity
                    }

                    BarConnectorCorner {
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        corner: RoundCorner.CornerEnum.TopRight
                        effectsOpacity: barContent.effectsOpacity
                    }
                }

                Item {
                    // Only the opaque corner shapes belong above BarContent.
                    // They cover the bar's bottom-edge shadow without putting
                    // the connector's own shadow on top of the panel.
                    z: 1
                    x: 0
                    y: Appearance.barHeight - 1
                    width: parent.width
                    height: Appearance.cornerSize

                    RoundCorner {
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                        implicitSize: Appearance.cornerSize
                        color: Appearance.barBgColor
                        corner: RoundCorner.CornerEnum.TopLeft
                    }

                    RoundCorner {
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        implicitSize: Appearance.cornerSize
                        color: Appearance.barBgColor
                        corner: RoundCorner.CornerEnum.TopRight
                    }
                }
            }

            Connections {
                target: NiriService

                function onOverviewOpenChanged() {
                    if (NiriService.overviewOpen)
                        barContent.closeOverlays();
                }
            }
        }
    }

    // A permanently mapped bar cannot acquire Niri's OnDemand focus from an
    // IPC request. Map only this tiny, non-interactive surface so the bar and
    // its popup keep their existing geometry and animation state.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notificationFocusWindow

            required property ShellScreen modelData
            property bool acquiredFocus: false

            screen: modelData
            visible: NotificationService.panelVisible
                && NotificationService.panelFocusProxyOutputName
                    === modelData.name
            implicitWidth: 2
            implicitHeight: 2

            anchors {
                top: true
                left: true
            }

            exclusionMode: ExclusionMode.Ignore
            color: Appearance.barBgColor

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace:
                "quickshell:notification-ipc-focus"
            WlrLayershell.keyboardFocus: visible
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Region {
                id: notificationFocusMask
            }

            mask: notificationFocusMask

            onVisibleChanged: {
                if (!visible) {
                    focusWindowDismissTimer.stop();
                    acquiredFocus = false;
                }
            }

            Item {
                readonly property bool hostWindowActive: Window.active

                onHostWindowActiveChanged: {
                    if (hostWindowActive) {
                        notificationFocusWindow.acquiredFocus = true;
                        focusWindowDismissTimer.stop();
                    } else if (notificationFocusWindow.visible
                            && notificationFocusWindow.acquiredFocus) {
                        focusWindowDismissTimer.restart();
                    }
                }
            }

            Timer {
                id: focusWindowDismissTimer

                interval: 120
                onTriggered: {
                    if (!notificationFocusWindow.visible
                            || !notificationFocusWindow.acquiredFocus) {
                        return;
                    }

                    if (NotificationService.panelHostFocusOutputName
                            === notificationFocusWindow.modelData.name) {
                        NotificationService.releasePanelFocusProxy(
                            notificationFocusWindow.modelData.name);
                    } else {
                        NotificationService.closePanel();
                    }
                }
            }
        }
    }

    // Keep the sidebar on its own layer-shell surface. Niri automatically
    // focuses a newly mapped OnDemand surface, including when it was opened
    // through Quickshell IPC. The always-mapped bar surface cannot trigger
    // that compositor behaviour by changing an Item's visibility alone.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sidebarWindow

            required property ShellScreen modelData
            readonly property real sidebarWidth:
                Math.min(Appearance.px(390),
                    Math.max(Appearance.px(320),
                        modelData.width * 0.32))
            property bool mappingEnabled: true
            property bool acquiredFocus: false

            screen: modelData
            visible: mappingEnabled && leftSidebar.surfaceVisible
            implicitWidth: sidebarWidth + Appearance.px(24)

            anchors {
                top: true
                bottom: true
                left: true
            }

            margins.top: Appearance.barHeight
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:left-sidebar"
            WlrLayershell.keyboardFocus: leftSidebar.shown
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Region {
                id: sidebarMask

                Region {
                    item: leftSidebar.maskItem
                }
            }

            mask: sidebarMask

            Timer {
                id: sidebarFocusDismissTimer

                interval: 120
                onTriggered: {
                    if (leftSidebar.shown
                            && sidebarWindow.acquiredFocus
                            && !leftSidebar.hostWindowActive
                            && !leftSidebar.pointerInside) {
                        leftSidebar.close();
                    }
                }
            }

            Connections {
                target: leftSidebar

                function onShownChanged() {
                    sidebarFocusDismissTimer.stop();

                    if (!leftSidebar.shown) {
                        sidebarWindow.acquiredFocus = false;
                        return;
                    }

                    sidebarWindow.acquiredFocus = false;
                    sidebarWindow.mappingEnabled = false;
                    Qt.callLater(() => {
                        if (leftSidebar.shown)
                            sidebarWindow.mappingEnabled = true;
                    });
                }

                function onPointerInsideChanged() {
                    if (leftSidebar.pointerInside) {
                        sidebarFocusDismissTimer.stop();
                    } else if (leftSidebar.shown
                            && sidebarWindow.acquiredFocus
                            && !leftSidebar.hostWindowActive) {
                        sidebarFocusDismissTimer.restart();
                    }
                }

                function onHostWindowActiveChanged() {
                    if (leftSidebar.hostWindowActive
                            && leftSidebar.shown) {
                        sidebarWindow.acquiredFocus = true;
                        sidebarFocusDismissTimer.stop();
                    } else if (leftSidebar.shown
                            && sidebarWindow.acquiredFocus
                            && !leftSidebar.pointerInside) {
                        sidebarFocusDismissTimer.restart();
                    }
                }
            }

            LeftSidebar {
                id: leftSidebar

                outputName: modelData.name
                width: sidebarWindow.sidebarWidth
                y: Appearance.px(5)
                height: Math.max(0,
                    parent.height - Appearance.px(10))
            }

            // The sidebar is remapped to acquire focus and therefore sits
            // above the Top-layer bar window. Redraw only the intersecting
            // connector fill in this window so the sidebar cannot cover it.
            // y = -1 keeps the curve aligned with the bar-side copy.
            RoundCorner {
                z: 100
                x: 0
                y: -1
                visible: leftSidebar.surfaceVisible
                implicitSize: Appearance.cornerSize
                color: Appearance.barBgColor
                corner: RoundCorner.CornerEnum.TopLeft
            }
        }
    }
}
