pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import qs.common
import qs.common.widgets

Item {
    id: root

    property bool shown: false
    property alias modules: moduleColumn.data
    readonly property bool pointerInside: sidebarHover.hovered
    readonly property Item maskItem: root
    readonly property real hiddenX:
        -width - Appearance.px(24)

    signal closeRequested

    function open() {
        shown = true;
        forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function close() {
        shown = false;
    }

    function toggle() {
        if (shown)
            close();
        else
            open();
    }

    x: shown ? 0 : hiddenX
    opacity: shown ? 1 : 0
    visible: shown || x > hiddenX + 0.5
    width: Math.min(Appearance.px(390),
        Math.max(Appearance.px(320),
            (parent?.width ?? Appearance.px(390)) * 0.32))

    focus: shown
    Keys.onEscapePressed: close()

    HoverHandler {
        id: sidebarHover
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.normalRadius
        color: Appearance.layer2
        border.width: 1
        border.color: Appearance.layer0Border

        layer.enabled: ShellSettings.shadowEnabled
        layer.effect: MultiEffect {
            shadowEnabled: ShellSettings.shadowEnabled
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Theme.palette.m3shadow, ShellSettings.shadowOpacity)
            shadowVerticalOffset: Math.round(
                ShellSettings.shadowOffsetY * Appearance.scale)
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: Appearance.px(14)
            }
            spacing: Appearance.px(12)

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(9)

                Rectangle {
                    implicitWidth: Appearance.px(36)
                    implicitHeight: Appearance.px(36)
                    radius: Appearance.px(11)
                    color: Appearance.primaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: Appearance.primaryContainerText
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(21)
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "QuickShell"
                        color: Appearance.layer0Text
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.largeFontSize
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: I18n.tr("sidebarModuleCount")
                            .arg(root.modules.length)
                        color: Appearance.subtext
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                        }
                    }
                }

                CloseButton {
                    onClicked: {
                        root.close();
                        root.closeRequested();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.outline
                opacity: 0.65
            }

            Controls.ScrollView {
                id: moduleScroll

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                Controls.ScrollBar.horizontal.policy:
                    Controls.ScrollBar.AlwaysOff
                Controls.ScrollBar.vertical.policy:
                    Controls.ScrollBar.AsNeeded

                ColumnLayout {
                    id: moduleColumn

                    width: moduleScroll.availableWidth
                    spacing: Appearance.px(10)
                }
            }
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.fastDuration
            easing.type: Easing.OutCubic
        }
    }
}
