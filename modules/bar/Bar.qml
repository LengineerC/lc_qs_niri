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
            readonly property real hiddenOffset:
                -Appearance.barHeight - Appearance.cornerSize

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

                function onHostWindowActiveChanged() {
                    if (barContent.hostWindowActive)
                        focusDismissTimer.stop();
                    else if (barContent.popupShown)
                        focusDismissTimer.restart();
                }

                function onPopupContainsMouseChanged() {
                    if (barContent.popupContainsMouse)
                        focusDismissTimer.stop();
                    else if (barContent.popupShown
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
                    effectsEnabled: NiriService.overviewProgress <= 0
                        || NiriService.overviewProgress >= 1
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
                        barContent.closePopup();
                }
            }
        }
    }
}
