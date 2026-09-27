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
    property Item draggedDelegate: null
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    readonly property var trayItems:
        ShellSettings.orderedTrayItems(SystemTray.items.values)
    readonly property bool menuOpen:
        contextMenu.visible
    readonly property bool menuContainsMouse:
        contextMenu.pointerInside
    readonly property int itemCount: trayItems.length
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

    onTrayItemsChanged: reconcileTimer.restart()

    onActiveChanged: {
        if (!active) {
            contextMenu.closeImmediately();
            finishTrayDrag(false);
        }
    }

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

    function startTrayDrag(delegate, index) {
        closeActiveMenu();
        draggedDelegate = delegate;
        dragSourceIndex = index;
        dragTargetIndex = index;
    }

    function updateTrayDrag(delegate, translationX, translationY) {
        if (draggedDelegate !== delegate || itemCount < 1)
            return;
        const point = delegate.mapToItem(
            trayGrid,
            delegate.width / 2 + translationX,
            delegate.height / 2 + translationY);
        const columnWidth = delegate.width + trayGrid.columnSpacing;
        const rowHeight = delegate.height + trayGrid.rowSpacing;
        const column = Math.max(0, Math.min(
            columnCount - 1,
            Math.floor(point.x / Math.max(1, columnWidth))));
        const row = Math.max(0, Math.floor(
            point.y / Math.max(1, rowHeight)));
        dragTargetIndex = Math.max(0, Math.min(
            itemCount - 1, row * columnCount + column));
    }

    function finishTrayDrag(commit) {
        if (!draggedDelegate)
            return;
        const sourceIndex = dragSourceIndex;
        const targetIndex = dragTargetIndex;
        draggedDelegate = null;
        dragSourceIndex = -1;
        dragTargetIndex = -1;
        if (commit && sourceIndex !== targetIndex) {
            ShellSettings.moveTrayItem(
                trayItems, sourceIndex, targetIndex);
        }
    }

    component PanelText: AppText {
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

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰀻"
                    color: Appearance.barSubtext
                    opacity: 0.7
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
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
                interactive: root.draggedDelegate === null
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: trayGrid

                    width: trayFlickable.width
                    columns: root.columnCount
                    columnSpacing: Appearance.px(5)
                    rowSpacing: Appearance.px(5)

                    Repeater {
                        model: ScriptModel {
                            values: root.trayItems
                            objectProp: "id"
                        }

                        delegate: Rectangle {
                            id: trayDelegate

                            required property int index
                            required property SystemTrayItem modelData
                            readonly property bool pinned:
                                ShellSettings.trayItemPinned(modelData)
                            readonly property bool beingDragged:
                                root.draggedDelegate === trayDelegate
                            readonly property bool dropTarget:
                                root.draggedDelegate
                                && root.dragTargetIndex === index
                                && root.dragSourceIndex !== index

                            width:
                                (trayGrid.width
                                    - trayGrid.columnSpacing
                                        * (root.columnCount - 1))
                                / root.columnCount
                            height: Appearance.px(56)
                            radius: Appearance.smallRadius
                            color: dropTarget
                                ? Appearance.barPrimaryContainer
                                : trayMouse.containsMouse
                                ? Appearance.barLayer1Hover
                                : modelData.status
                                    === Status.NeedsAttention
                                    ? Appearance.barPrimaryContainer
                                    : Appearance.barLayer1
                            border.width: dropTarget ? 2 : 1
                            border.color: dropTarget
                                ? Appearance.barPrimary
                                : modelData.status
                                    === Status.NeedsAttention
                                    || pinned
                                ? Appearance.barPrimary
                                : Appearance.barOutline
                            scale: beingDragged ? 0.94
                                : trayMouse.pressed ? 0.8 : 0.85
                            opacity: beingDragged ? 0.88 : 1
                            z: beingDragged ? 4 : 0

                            transform: Translate {
                                x: trayDelegate.beingDragged
                                    ? trayDrag.activeTranslation.x : 0
                                y: trayDelegate.beingDragged
                                    ? trayDrag.activeTranslation.y : 0
                            }

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

                            DragHandler {
                                id: trayDrag

                                target: null
                                acceptedButtons: Qt.LeftButton
                                dragThreshold: Appearance.px(5)

                                onActiveChanged: {
                                    if (active) {
                                        root.startTrayDrag(
                                            trayDelegate,
                                            trayDelegate.index);
                                        root.updateTrayDrag(
                                            trayDelegate,
                                            activeTranslation.x,
                                            activeTranslation.y);
                                    } else if (trayDelegate.beingDragged) {
                                        root.finishTrayDrag(true);
                                    }
                                }

                                onActiveTranslationChanged:
                                    root.updateTrayDrag(
                                        trayDelegate,
                                        activeTranslation.x,
                                        activeTranslation.y)
                            }

                            Rectangle {
                                id: pinBadge

                                z: 2
                                visible: trayDelegate.pinned
                                    || trayMouse.containsMouse
                                    || pinMouse.containsMouse
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    topMargin: Appearance.px(3)
                                    rightMargin: Appearance.px(3)
                                }
                                width: Appearance.px(19)
                                height: width
                                radius: Appearance.fullRadius
                                color: trayDelegate.pinned
                                    ? Appearance.barPrimaryContainer
                                    : Appearance.barLayer1Hover
                                border.width: 1
                                border.color: trayDelegate.pinned
                                    ? Appearance.barPrimary
                                    : Appearance.barOutline

                                AppText {
                                    anchors.centerIn: parent
                                    text: "󰐃"
                                    color: trayDelegate.pinned
                                        ? Appearance.barPrimaryContainerText
                                        : Appearance.barLayer1Text
                                    font {
                                        family: Appearance.iconFontFamily
                                        weight: Font.Normal
                                        pixelSize: Appearance.px(11)
                                    }
                                }

                                MouseArea {
                                    id: pinMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellSettings
                                        .toggleTrayItemPinned(
                                            trayDelegate.modelData)
                                }

                                StyledToolTip {
                                    visible: pinMouse.containsMouse
                                        && !root.menuOpen
                                    text: trayDelegate.pinned
                                        ? I18n.tr("unpinFromBar")
                                        : I18n.tr("pinToBar")
                                    delay: 350
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

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.fastDuration
                                }
                            }

                            Behavior on x {
                                enabled: !trayDelegate.beingDragged
                                NumberAnimation {
                                    duration: Appearance.fastDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on y {
                                enabled: !trayDelegate.beingDragged
                                NumberAnimation {
                                    duration: Appearance.fastDuration
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

        // RowLayout {
        //     Layout.fillWidth: true
        //     Layout.leftMargin: Appearance.px(8)
        //     Layout.rightMargin: Appearance.px(8)
        //     visible: root.itemCount > 0
        //     spacing: Appearance.px(7)

        //     AppText {
        //         text: "󰐃"
        //         color: Appearance.barPrimary
        //         font {
        //             family: Appearance.iconFontFamily
        //             weight: Font.Normal
        //             pixelSize: Appearance.px(13)
        //         }
        //     }

        //     PanelText {
        //         Layout.fillWidth: true
        //         text: I18n.tr("trayPinHint")
        //         color: Appearance.barSubtext
        //         font.pixelSize: Appearance.smallFontSize
        //     }
        // }
    }

    TrayContextMenu {
        id: contextMenu

        onMenuOpened: menu => root.activeMenu = menu
        onMenuDismissed: {
            root.activeMenu = null;
        }
    }
}
