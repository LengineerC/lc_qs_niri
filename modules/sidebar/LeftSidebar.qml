pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    required property string outputName
    readonly property bool shown:
        LeftSidebarService.shown
        && root.outputName.length > 0
        && LeftSidebarService.targetOutputName
            === root.outputName
    property alias modules: moduleColumn.data
    readonly property bool pointerInside: sidebarHover.hovered
    readonly property Item maskItem: root
    readonly property real hiddenX:
        -width - Appearance.px(24)
    
    signal closeRequested

    function open() {
        LeftSidebarService.open();
    }

    function close() {
        LeftSidebarService.close();
    }

    function toggle() {
        LeftSidebarService.toggle();
    }

    x: shown ? 5 : hiddenX
    opacity: shown ? 1 : 0
    visible: shown || x > hiddenX + 0.5
    width: Math.min(Appearance.px(390),
        Math.max(Appearance.px(320),
            (parent?.width ?? Appearance.px(390)) * 0.32))

    focus: shown
    Keys.onEscapePressed: event => {
        root.close();
        event.accepted = true;
    }

    HoverHandler {
        id: sidebarHover
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.cornerSize
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

            Controls.ScrollView {
                id: moduleScroll

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                Controls.ScrollBar.horizontal.policy:
                    Controls.ScrollBar.AlwaysOff
                Controls.ScrollBar.vertical.policy:
                    Controls.ScrollBar.AlwaysOff

                MouseArea {
                    anchors.fill: parent
                    onClicked: forceActiveFocus()
                }
                
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
            duration: Appearance.spatialDuration
            easing.type: Easing.OutCubic
        }
    }
}
