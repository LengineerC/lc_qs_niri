pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.common.widgets
import qs.modules.sidebar
import qs.services

Scope {
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
            WlrLayershell.keyboardFocus: barContent.popupShown
                    || barContent.barContainsMouse
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Region {
                id: normalMask

                Region {
                    item: barContent.barMask
                }
                Region {
                    item: barContent.popupMask
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: forceActiveFocus()
            }

            mask: normalMask

            Timer {
                id: focusDismissTimer

                interval: 120
                onTriggered: {
                    if (barContent.popupShown
                            && !barContent.hostWindowActive
                            && !barContent.popupContainsMouse) {
                        barContent.closePopup();
                    }
                }
            }

            Connections {
                target: barContent

                function onPopupShownChanged() {
                    if (!barContent.popupShown)
                        return;

                    // The hover binding above lets Niri focus this surface
                    // on the opening click. Also request activation after
                    // bindings have settled for keyboard/touch activation.
                    focusDismissTimer.stop();
                    barContent.requestHostWindowFocus();
                    Qt.callLater(
                        () => barContent.requestHostWindowFocus());
                }

                function onHostWindowActiveChanged() {
                    if (barContent.hostWindowActive) {
                        focusDismissTimer.stop();
                    } else if (barContent.popupShown) {
                        focusDismissTimer.restart();
                    }
                }

                function onPopupContainsMouseChanged() {
                    if (barContent.popupContainsMouse) {
                        focusDismissTimer.stop();
                    } else if (barContent.popupShown
                            && !barContent.hostWindowActive) {
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
                enabled: !NiriService.overviewOpen
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
                modules: [
                    FastfetchCard {},
                    SidebarUtilityRow {},
                    QuickNote {},
                    DayProgressCard {
                        active: leftSidebar.shown
                    },
                ]
            }
        }
    }
}
