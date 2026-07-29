pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.common.widgets

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow

            required property ShellScreen modelData
            property bool popupWasFocused: false

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: modelData.height
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
                    item: barContent
                }
                Region {
                    item: barContent.popupMask
                }
            }

            Region {
                id: dismissMask

                x: 0
                y: 0
                width: barWindow.width
                height: barWindow.height
            }

            mask: barContent.popupShown ? dismissMask : normalMask

            MouseArea {
                anchors.fill: parent
                enabled: barContent.popupShown
                onClicked: barContent.closePopup()
            }

            Connections {
                target: barContent

                function onPopupShownChanged() {
                    barWindow.popupWasFocused = barContent.popupShown
                        && barContent.hostWindowActive;
                }
            }

            Connections {
                target: barContent

                function onHostWindowActiveChanged() {
                    if (barContent.hostWindowActive && barContent.popupShown) {
                        barWindow.popupWasFocused = true;
                    } else if (!barContent.hostWindowActive
                        && barWindow.popupWasFocused
                        && barContent.popupShown) {
                        barContent.closePopup();
                    }
                }
            }

            BarContent {
                id: barContent
                outputName: modelData.name
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
            }

            Item {
                height: Appearance.cornerSize
                anchors {
                    top: barContent.bottom
                    topMargin: -1
                    left: parent.left
                    right: parent.right
                }

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
    }
}
