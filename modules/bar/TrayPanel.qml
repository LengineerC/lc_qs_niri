pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.common
import qs.common.widgets

Item {
    id: root

    signal closeRequested

    property bool active: true
    property var activeMenu: null
    readonly property bool menuOpen:
        contextMenu.visible
    readonly property bool menuContainsMouse:
        contextMenu.pointerInside
    readonly property int itemCount:
        SystemTray.items.values.length
    readonly property int columnCount: 5
    readonly property int rowCount:
        Math.ceil(itemCount / columnCount)
    readonly property int gridHeight: itemCount > 0
        ? rowCount * Appearance.px(56)
            + Math.max(0, rowCount - 1) * Appearance.px(7)
        : Appearance.px(86)

    implicitWidth: Appearance.px(330)
    readonly property int baseImplicitHeight:
        contentColumn.implicitHeight + Appearance.px(8)

    implicitHeight: baseImplicitHeight

    onActiveChanged: {
        if (!active)
            contextMenu.closeImmediately();
    }

    function itemTitle(item) {
        return String(item?.tooltipTitle
            || item?.title || item?.id
            || I18n.tr("unknownApplication"));
    }

    function closeActiveMenu() {
        contextMenu.closeMenu();
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

    component PanelText: Text {
        color: Appearance.barLayer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Appearance.px(5)
        }
        spacing: Appearance.px(10)

        // PopupHeader {
        //     useBarPalette: true
        //     icon: "󰀻"
        //     iconSize: Appearance.px(20)
        //     title: I18n.tr("systemTray")
        //     dividerSpacing: Appearance.px(10)
        //     onCloseClicked: {
        //         root.closeActiveMenu();
        //         root.closeRequested();
        //     }
        // }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(
                root.gridHeight, Appearance.px(308))

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.itemCount === 0
                spacing: Appearance.px(7)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰀻"
                    color: Appearance.barSubtext
                    opacity: 0.7
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(32)
                    }
                }

                PanelText {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("noTrayApplications")
                    color: Appearance.barSubtext
                }
            }

            Flickable {
                id: trayFlickable

                anchors.fill: parent
                visible: root.itemCount > 0
                contentWidth: width
                contentHeight: trayGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: trayGrid

                    width: trayFlickable.width
                    columns: root.columnCount
                    columnSpacing: Appearance.px(5)
                    rowSpacing: Appearance.px(5)

                    Repeater {
                        // UntypedObjectModel keeps delegates stable while
                        // applications update or blink their tray icon.
                        model: SystemTray.items

                        delegate: Rectangle {
                            id: trayDelegate

                            required property SystemTrayItem modelData

                            width:
                                (trayGrid.width
                                    - trayGrid.columnSpacing
                                        * (root.columnCount - 1))
                                / root.columnCount
                            height: Appearance.px(56)
                            radius: Appearance.smallRadius
                            color: trayMouse.containsMouse
                                ? Appearance.barLayer1Hover
                                : modelData.status
                                    === Status.NeedsAttention
                                    ? Appearance.barPrimaryContainer
                                    : Appearance.barLayer1
                            border.width: 1
                            border.color: modelData.status
                                    === Status.NeedsAttention
                                ? Appearance.barPrimary
                                : Appearance.barOutline
                            scale: trayMouse.pressed ? 0.8 : 0.85

                            function openMenu() {
                                return root.openContextMenu(
                                    modelData, trayDelegate);
                            }

                            Image {
                                id: trayIcon

                                anchors.centerIn: parent
                                width: Appearance.px(28)
                                height: Appearance.px(28)
                                source: trayDelegate.modelData.icon
                                sourceSize.width: Appearance.px(28)
                                sourceSize.height: Appearance.px(28)
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

                            PanelText {
                                anchors.centerIn: parent
                                visible: !trayIcon.source
                                    || trayIcon.status === Image.Error
                                text: root.itemTitle(
                                    trayDelegate.modelData)
                                    .slice(0, 1).toUpperCase()
                                color: Appearance.barPrimary
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: trayMouse

                                anchors.fill: parent
                                acceptedButtons:
                                    Qt.LeftButton
                                    | Qt.RightButton
                                hoverEnabled: true
                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: event => {
                                    if (event.button
                                            === Qt.RightButton) {
                                        if (!trayDelegate.openMenu())
                                            trayDelegate.modelData
                                                .secondaryActivate();
                                        return;
                                    }

                                    if (trayDelegate.modelData
                                            .onlyMenu
                                        && trayDelegate.openMenu())
                                        return;
                                    trayDelegate.modelData.activate();
                                    root.closeActiveMenu();
                                    root.closeRequested();
                                }
                            }

                            StyledToolTip {
                                visible: trayMouse.containsMouse
                                    && !root.menuOpen
                                text: root.itemTitle(modelData)
                                delay: 500
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration:
                                        Appearance.fastDuration
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration:
                                        Appearance.fastDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                Controls.ScrollBar.vertical:
                    Controls.ScrollBar {
                        policy: Controls.ScrollBar.AsNeeded
                    }
            }
        }
    }

    TrayContextMenu {
        id: contextMenu

        onMenuOpened: menu => root.activeMenu = menu
        onMenuDismissed: {
            root.activeMenu = null;
        }
    }
}
