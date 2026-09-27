pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import qs.common
import qs.common.widgets

Item {
    id: root

    signal activated
    signal closeRequested

    property bool expanded: false
    readonly property bool hostWindowActive: Window.active
    readonly property bool menuOpen: contextMenu.visible
    readonly property bool menuContainsMouse: contextMenu.pointerInside
    readonly property var trayItems:
        ShellSettings.orderedTrayItems(SystemTray.items.values)
    readonly property var pinnedItems:
        trayItems.filter(item => ShellSettings.trayItemPinned(item))
    readonly property bool needsAttention:
        SystemTray.items.values.some(item =>
            item?.status === Status.NeedsAttention)

    implicitWidth: trayRow.implicitWidth
    implicitHeight: Appearance.barHeight

    onTrayItemsChanged: reconcileTimer.restart()

    Component.onCompleted: reconcileTimer.restart()

    Timer {
        id: reconcileTimer

        interval: 0
        onTriggered: ShellSettings.reconcileTrayItems(
            SystemTray.items.values)
    }

    Connections {
        target: ShellSettings

        function onReadyChanged() {
            if (ShellSettings.ready)
                reconcileTimer.restart();
        }
    }

    function itemTitle(item) {
        return String(item?.tooltipTitle
            || item?.title || item?.id
            || I18n.tr("unknownApplication"));
    }

    function openContextMenu(item, anchor) {
        if (!item?.hasMenu)
            return false;
        contextMenu.switchToMenu(
            item.menu,
            anchor,
            itemTitle(item),
            item.icon);
        return true;
    }

    function closeContextMenu() {
        menuDismissTimer.stop();
        contextMenu.closeMenu();
    }

    onHostWindowActiveChanged: {
        if (hostWindowActive) {
            menuDismissTimer.stop();
        } else if (contextMenu.visible
                && !contextMenu.pointerInside) {
            menuDismissTimer.restart();
        }
    }

    Timer {
        id: menuDismissTimer

        interval: 120
        onTriggered: {
            if (!contextMenu.visible
                    || root.hostWindowActive
                    || contextMenu.pointerInside)
                return;
            if (contextMenu.navigationInProgress
                    || contextMenu.pointerGraceActive) {
                restart();
                return;
            }
            contextMenu.closeMenu();
        }
    }

    Row {
        id: trayRow

        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: Appearance.px(2)

        MouseArea {
            id: trayToggle

            width: Appearance.px(30)
            height: root.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                contextMenu.closeMenu();
                root.activated();
            }

            Rectangle {
                width: Appearance.px(30)
                height: Appearance.px(30)
                anchors.centerIn: parent
                radius: Appearance.fullRadius
                color: trayToggle.containsMouse || root.expanded
                    ? Appearance.barLayer1Hover
                    : Appearance.withAlpha(
                        Appearance.barLayer1Hover, 0)
                scale: trayToggle.pressed ? 0.88 : 1

                AppText {
                    anchors.centerIn: parent
                    text: ""
                    rotation: root.expanded ? 180 : 0
                    color: root.needsAttention
                        ? Appearance.barPrimary
                        : Appearance.barLayer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.px(11)
                        weight: Font.Bold
                    }

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    visible: root.needsAttention
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: Appearance.px(4)
                        rightMargin: Appearance.px(4)
                    }
                    width: Appearance.px(6)
                    height: width
                    radius: width / 2
                    color: Appearance.barTertiary
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

        Repeater {
            model: ScriptModel {
                values: root.pinnedItems
                objectProp: "id"
            }

            delegate: MouseArea {
                id: pinnedDelegate

                required property SystemTrayItem modelData

                width: Appearance.px(30)
                height: root.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: event => {
                    if (event.button === Qt.RightButton) {
                        if (!root.openContextMenu(
                                modelData, pinnedDelegate)) {
                            modelData.secondaryActivate();
                        }
                        return;
                    }

                    if (modelData.onlyMenu
                            && root.openContextMenu(
                                modelData, pinnedDelegate)) {
                        return;
                    }
                    modelData.activate();
                    contextMenu.closeMenu();
                    root.closeRequested();
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Appearance.px(30)
                    height: Appearance.px(30)
                    radius: Appearance.fullRadius
                    color: pinnedDelegate.containsMouse
                        ? Appearance.barLayer1Hover
                        : Appearance.withAlpha(
                            Appearance.barLayer1Hover, 0)
                    scale: pinnedDelegate.pressed ? 0.88 : 1

                    Image {
                        id: pinnedIcon

                        anchors.centerIn: parent
                        width: Appearance.px(19)
                        height: Appearance.px(19)
                        source: pinnedDelegate.modelData.icon
                        sourceSize.width: Appearance.px(19)
                        sourceSize.height: Appearance.px(19)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
                        smooth: true
                        opacity: ShellSettings.monochromeAppIconsActive
                            ? Appearance.monochromeAppIconOpacity : 1
                        layer.enabled:
                            ShellSettings.monochromeAppIconsActive
                        layer.effect: MultiEffect {
                            saturation: -1
                            brightness: 0.12
                            contrast: 0.08
                        }
                    }

                    AppText {
                        anchors.centerIn: parent
                        visible: !pinnedIcon.source
                            || pinnedIcon.status === Image.Error
                        text: root.itemTitle(
                            pinnedDelegate.modelData)
                            .slice(0, 1).toUpperCase()
                        color: Appearance.barPrimary
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        visible: pinnedDelegate.modelData.status
                            === Status.NeedsAttention
                        anchors {
                            top: parent.top
                            right: parent.right
                            topMargin: Appearance.px(2)
                            rightMargin: Appearance.px(2)
                        }
                        width: Appearance.px(6)
                        height: width
                        radius: width / 2
                        color: Appearance.barTertiary
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

                StyledToolTip {
                    visible: pinnedDelegate.containsMouse
                        && !contextMenu.visible
                    text: root.itemTitle(pinnedDelegate.modelData)
                    delay: 500
                }
            }
        }
    }

    TrayContextMenu {
        id: contextMenu

        onVisibleChanged: {
            if (!visible) {
                menuDismissTimer.stop();
            } else if (!root.hostWindowActive
                    && !pointerInside) {
                menuDismissTimer.restart();
            }
        }

        onPointerInsideChanged: {
            if (pointerInside) {
                menuDismissTimer.stop();
            } else if (visible && !root.hostWindowActive) {
                menuDismissTimer.restart();
            }
        }
    }
}
