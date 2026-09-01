pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.common.widgets

PopupWindow {
    id: root

    property var menuHandle: null
    property Item anchorItem: null
    property string menuTitle: ""
    property string menuIcon: ""
    property bool presented: false
    property bool openedOnce: false
    property bool switchingMenu: false
    property int switchGeneration: 0
    readonly property bool pointerInside: menuHover.hovered

    signal menuOpened(var menu)
    signal menuDismissed

    readonly property int outerPadding: Appearance.px(15)
    readonly property int contentWidth: Appearance.px(280)

    color: "transparent"
    visible: false
    // This is intentionally non-grabbing. The parent Bar already owns focus,
    // while a second Wayland popup grab can be rejected during the same click
    // that activates the Bar and leave the popup in a broken state.
    grabFocus: false
    implicitWidth: contentWidth + outerPadding * 2
    implicitHeight: menuCard.implicitHeight + outerPadding * 2

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.SlideX
            | PopupAdjustment.ResizeY
    }

    function clearMenuPages() {
        menuStack.clear(Controls.StackView.Immediate);
    }

    function rebuildRootMenu() {
        clearMenuPages();
        menuStack.push(
            submenuComponent.createObject(menuStack, {
                "handle": root.menuHandle,
                "submenuTitle": root.menuTitle,
                "isSubmenu": false
            }),
            Controls.StackView.Immediate);
    }

    function switchToMenu(handle, newAnchor, title, icon) {
        const generation = ++switchGeneration;
        closeTimer.stop();
        switchingMenu = true;
        presented = false;

        // Destroy every delegate backed by the previous QsMenuOpener before
        // assigning the next handle. Merely changing handle leaves the old
        // object model alive until the DBus update completes.
        clearMenuPages();
        menuHandle = handle;
        anchorItem = newAnchor;
        menuTitle = title;
        menuIcon = icon;
        rebuildRootMenu();

        openedOnce = true;
        if (!visible)
            visible = true;
        root.menuOpened(root);
        positionTimer.generation = generation;
        positionTimer.restart();
    }

    function openMenu() {
        switchToMenu(
            menuHandle, anchorItem, menuTitle, menuIcon);
    }

    function closeMenu() {
        if (!visible)
            return;
        presented = false;
        closeTimer.restart();
    }

    function closeImmediately() {
        ++switchGeneration;
        closeTimer.stop();
        switchingMenu = false;
        presented = false;
        visible = false;
    }

    onClosed: closeImmediately()

    onVisibleChanged: {
        if (!visible && openedOnce) {
            openedOnce = false;
            clearMenuPages();
            root.menuDismissed();
        }
    }

    Timer {
        id: closeTimer

        interval: Math.max(80, Appearance.fastDuration)
        onTriggered: root.visible = false
    }

    Timer {
        id: positionTimer

        property int generation: 0

        // DBusMenu children can arrive over several event-loop turns. Wait
        // until the card height has stopped changing, then position once.
        interval: 55
        onTriggered: {
            if (generation !== root.switchGeneration
                    || !root.visible)
                return;
            root.anchor.updateAnchor();
            root.switchingMenu = false;
            root.presented = true;
            menuFocus.forceActiveFocus();
        }
    }

    FocusScope {
        id: menuFocus

        anchors.fill: parent
        focus: root.visible

        HoverHandler {
            id: menuHover
        }

        Keys.onEscapePressed: event => {
            if (menuStack.depth > 1)
                menuStack.pop();
            else
                root.closeMenu();
            event.accepted = true;
        }

        Rectangle {
            id: menuCard

            x: root.outerPadding
            y: root.outerPadding
                + (root.presented
                    ? 0 : -Appearance.px(5))
            implicitWidth: root.contentWidth
            implicitHeight: menuLayout.implicitHeight
                + Appearance.px(12)
            radius: Appearance.normalRadius
            // PopupWindow cannot reliably constrain Niri's blur to its card
            // bounds. Use a denser translucent black surface so the menu
            // matches glass panels without leaking blur into its padding.
            color: ShellSettings.barFrostedGlass
                ? Appearance.withAlpha(
                    Appearance.barGlassBaseColor, 0.9)
                : Appearance.layer0
            border.width: 1
            border.color: Appearance.barOutline
            opacity: root.presented ? 1 : 0
            scale: root.presented ? 1 : 0.96
            transformOrigin: Item.Top
            clip: true

            onImplicitHeightChanged: {
                if (root.switchingMenu)
                    positionTimer.restart();
            }

            layer.enabled: ShellSettings.shadowEnabled
            layer.effect: MultiEffect {
                shadowEnabled: ShellSettings.shadowEnabled
                shadowBlur: 1
                blurMax: Math.max(1, Math.round(
                    ShellSettings.shadowBlurRadius
                        * Appearance.scale))
                shadowColor: Appearance.withAlpha(
                    Appearance.barShadow,
                    ShellSettings.shadowOpacity)
                shadowVerticalOffset: Math.round(
                    ShellSettings.shadowOffsetY
                        * Appearance.scale)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                    | Qt.RightButton
                onClicked: event => event.accepted = true
            }

            ColumnLayout {
                id: menuLayout

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Appearance.px(6)
                }
                spacing: Appearance.px(4)

                PopupHeader {
                    useBarPalette: true
                    icon: "󰀻"
                    iconSource: root.menuIcon
                    iconSize: String(root.menuIcon).length > 0
                        ? Appearance.px(22) : Appearance.px(17)
                    iconSlotSize: Appearance.px(24)
                    monochromeIcon: true
                    title: root.menuTitle
                    titleFontSize: Appearance.fontSize
                    contentLeftMargin: Appearance.px(6)
                    dividerLeftMargin: Appearance.px(5)
                    dividerRightMargin: Appearance.px(5)
                    dividerSpacing: Appearance.px(4)
                    dividerOpacity: 0.6
                    onCloseClicked: root.closeMenu()
                }

                Controls.StackView {
                    id: menuStack

                    Layout.fillWidth: true
                    implicitHeight: currentItem?.implicitHeight ?? 0
                    pushEnter: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "x"
                                from: Appearance.px(18)
                                to: 0
                                duration: Appearance.fastDuration
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: Appearance.fastDuration
                            }
                        }
                    }
                    pushExit: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Appearance.fastDuration
                        }
                    }
                    popEnter: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "x"
                                from: -Appearance.px(18)
                                to: 0
                                duration: Appearance.fastDuration
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: Appearance.fastDuration
                            }
                        }
                    }
                    popExit: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Appearance.fastDuration
                        }
                    }

                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Behavior on opacity {
                enabled: !root.switchingMenu
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                enabled: !root.switchingMenu
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.8
                }
            }

            Behavior on y {
                enabled: !root.switchingMenu
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Component {
        id: submenuComponent

        Item {
            id: submenu

            property var handle: null
            required property string submenuTitle
            required property bool isSubmenu

            // StackView does not own objects passed to push()/replace().
            // Explicit destruction prevents removed DBus menu pages from
            // continuing to render underneath the next application menu.
            Controls.StackView.onRemoved: submenu.destroy()

            readonly property var entries:
                menuOpener.children?.values ?? []
            readonly property bool iconColumnNeeded:
                entries.some(entry =>
                    String(entry?.icon ?? "").length > 0)
            readonly property bool controlColumnNeeded:
                entries.some(entry => entry?.buttonType
                    !== QsMenuButtonType.None)

            implicitWidth: root.contentWidth
                - Appearance.px(12)
            implicitHeight: Math.min(
                menuColumn.implicitHeight,
                Appearance.px(460))

            Component.onDestruction: {
            }

            QsMenuOpener {
                id: menuOpener
                menu: submenu.handle
            }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: menuColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: menuColumn

                    width: parent.width
                    spacing: 0

                    Rectangle {
                        visible: submenu.isSubmenu
                        Layout.fillWidth: true
                        implicitHeight: visible
                            ? Appearance.px(40) : 0
                        radius: Appearance.px(10)
                        color: backMouse.containsMouse
                            ? Appearance.barLayer1Hover
                            : Appearance.withAlpha(
                                Appearance.barLayer1Hover, 0)

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(10)
                                rightMargin: Appearance.px(10)
                            }
                            spacing: Appearance.px(8)

                            Text {
                                text: "󰅁"
                                color: Appearance.barPrimary
                                font {
                                    family: Appearance.iconFontFamily
                                    pixelSize: Appearance.px(15)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: submenu.submenuTitle
                                color: Appearance.barLayer0Text
                                elide: Text.ElideRight
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.fontSize
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: backMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: menuStack.pop()
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fastDuration
                            }
                        }
                    }

                    Repeater {
                        model: menuOpener.children

                        delegate: TrayMenuEntry {
                            required property QsMenuEntry modelData

                            menuEntry: modelData
                            forceIconColumn:
                                submenu.iconColumnNeeded
                            forceControlColumn:
                                submenu.controlColumnNeeded

                            onDismiss: root.closeMenu()
                            onOpenSubmenu:
                                (handle, title) => {
                                    menuStack.push(
                                        submenuComponent
                                            .createObject(
                                                menuStack, {
                                                    "handle":
                                                        handle,
                                                    "submenuTitle":
                                                        title,
                                                    "isSubmenu":
                                                        true
                                                }));
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
}
