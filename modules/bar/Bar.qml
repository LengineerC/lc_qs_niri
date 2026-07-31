pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.common.widgets
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
                    || barContent.sidebarShown
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
                Region {
                    item: barContent.sidebarMask
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
                    if ((barContent.popupShown
                            || barContent.sidebarShown)
                            && !barContent.hostWindowActive
                            && !barContent.popupContainsMouse
                            && !barContent.sidebarContainsMouse) {
                        barContent.closeOverlays();
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

                function onSidebarShownChanged() {
                    if (!barContent.sidebarShown)
                        return;

                    focusDismissTimer.stop();
                    barContent.requestHostWindowFocus();
                    Qt.callLater(
                        () => barContent.requestHostWindowFocus());
                }

                function onHostWindowActiveChanged() {
                    if (barContent.hostWindowActive)
                        focusDismissTimer.stop();
                    else if (barContent.popupShown
                            || barContent.sidebarShown)
                        focusDismissTimer.restart();
                }

                function onPopupContainsMouseChanged() {
                    if (barContent.popupContainsMouse)
                        focusDismissTimer.stop();
                    else if ((barContent.popupShown
                            || barContent.sidebarShown)
                        && !barContent.sidebarContainsMouse
                        && !barContent.hostWindowActive) {
                        focusDismissTimer.restart();
                    }
                }

                function onSidebarContainsMouseChanged() {
                    if (barContent.sidebarContainsMouse)
                        focusDismissTimer.stop();
                    else if ((barContent.popupShown
                            || barContent.sidebarShown)
                        && !barContent.popupContainsMouse
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
}
