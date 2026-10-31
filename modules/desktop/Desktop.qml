pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.common.widgets
import qs.services

Scope {
    Variants {
        model: Quickshell.screens.filter(screen => screen && screen.name)
        PanelWindow {
            id: window
            required property ShellScreen modelData
            screen: modelData
            color: "transparent"
            exclusiveZone: -1
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:desktop"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Item {
                id: surface
                anchors.fill: parent
                anchors.topMargin: ShellSettings.barPosition === "top" ? Appearance.barHeight : 0
                anchors.bottomMargin: ShellSettings.barPosition === "bottom" ? Appearance.barHeight : 0
                anchors.leftMargin: ShellSettings.barPosition === "left" ? Appearance.barHeight : 0
                anchors.rightMargin: ShellSettings.barPosition === "right" ? Appearance.barHeight : 0
                property var selected: []
                property var dragOrigins: []
                property bool moving: false
                property var contextEntries: []
                function openContext(name) {
                    if (!selected.includes(name))
                        selected = [name];
                    contextEntries = DesktopService.entries.filter(entry => selected.includes(entry.name));
                    entryMenu.popup();
                }
                property string renameName: ""
                property bool renamePending: false
                property var renameField: null
                function showRename() {
                    if (contextEntries.length !== 1 || !contextEntries[0].link)
                        return;
                    renameName = contextEntries[0].name;
                    renamePending = false;
                    Qt.callLater(() => {
                        for (let i = 0; i < icons.count; ++i) {
                            const item = icons.itemAt(i);
                            if (item && item.modelData.name === renameName)
                                item.beginRename();
                        }
                    });
                }
                function cancelRename() {
                    if (renamePending)
                        return;
                    renameName = "";
                    renameField = null;
                }
                function choose(name, modifiers) {
                    const toggle = modifiers & Qt.ControlModifier;
                    if (toggle)
                        selected = selected.includes(name) ? selected.filter(n => n !== name) : selected.concat([name]);
                    else
                        selected = [name];
                }
                function beginMove() {
                    const origins = [];
                    for (let i = 0; i < icons.count; ++i) {
                        const item = icons.itemAt(i);
                        if (item && selected.includes(item.modelData.name))
                            origins.push({item: item, x: item.x, y: item.y});
                    }
                    dragOrigins = origins;
                }
                function moveGroup(source, dx, dy) {
                    moving = true;
                    for (const entry of dragOrigins) {
                        if (entry.item !== source) {
                            entry.item.x = entry.x + dx;
                            entry.item.y = entry.y + dy;
                        }
                    }
                }
                function finishMove() {
                    if (moving) {
                        DesktopService.moveMany(dragOrigins.filter(entry => entry.item).map(entry => ({name: entry.item.modelData.name,
                            x: entry.item.x, y: entry.item.y})), window.modelData.name);
                    }
                    moving = false;
                    dragOrigins = [];
                }
                Connections {
                    target: DesktopService
                    function onErrorChanged() {
                        if (DesktopService.error && surface.renamePending) {
                            surface.renamePending = false;
                            if (surface.renameField)
                                surface.renameField.forceActiveFocus();
                        }
                    }
                    function onEntriesChanged() {
                        if (surface.renameName && !DesktopService.entries.some(e => e.name === surface.renameName)) {
                            surface.renamePending = false;
                            surface.cancelRename();
                        }
                        surface.moving = false;
                        surface.dragOrigins = [];
                        surface.selected = surface.selected.filter(name => DesktopService.entries.some(e => e.name === name));
                    }
                }
                readonly property int cellWidth: Appearance.px(120)
                readonly property int cellHeight: Appearance.px(132)
                readonly property int rows: Math.max(1, Math.floor(height / cellHeight))

                MouseArea {
                    id: selectionMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    property bool selecting: false
                    property real startX: 0
                    property real startY: 0
                    property real endX: 0
                    property real endY: 0
                    property var previous: []
                    onPressed: mouse => {
                        if (surface.renameField)
                            surface.renameField.commit();
                        if (mouse.button === Qt.RightButton) {
                            desktopMenu.popup();
                            return;
                        }
                        previous = (mouse.modifiers & Qt.ControlModifier) ? surface.selected.slice() : [];
                        surface.selected = previous.slice();
                        startX = endX = mouse.x;
                        startY = endY = mouse.y;
                        selecting = true;
                    }
                    onPositionChanged: mouse => {
                        if (!selecting)
                            return;
                        endX = mouse.x;
                        endY = mouse.y;
                        const names = previous.slice();
                        for (let i = 0; i < icons.count; ++i) {
                            const item = icons.itemAt(i);
                            if (item && item.x < selectionBox.x + selectionBox.width
                                && item.x + item.width > selectionBox.x
                                && item.y < selectionBox.y + selectionBox.height
                                && item.y + item.height > selectionBox.y
                                && !names.includes(item.modelData.name))
                                names.push(item.modelData.name);
                        }
                        surface.selected = names;
                    }
                    onReleased: selecting = false
                    onCanceled: selecting = false
                }
                Rectangle {
                    id: selectionBox
                    z: 2
                    visible: selectionMouse.selecting
                    x: Math.min(selectionMouse.startX, selectionMouse.endX)
                    y: Math.min(selectionMouse.startY, selectionMouse.endY)
                    width: Math.abs(selectionMouse.endX - selectionMouse.startX)
                    height: Math.abs(selectionMouse.endY - selectionMouse.startY)
                    color: Appearance.withAlpha(Appearance.primary, 0.18)
                    border.color: Appearance.primary
                    border.width: 1
                    radius: Appearance.px(4)
                }
                DropArea {
                    anchors.fill: parent
                    onEntered: drag => { drag.accepted = drag.hasUrls; }
                    onDropped: drop => {
                        if (!drop.hasUrls)
                            return;
                        // Report LinkAction so the source never removes its originals.
                        drop.accept(Qt.LinkAction);
                        DesktopService.addAt(drop.urls.map(url => String(url)),
                            window.modelData.name,
                            Math.max(0, Math.min(drop.x - surface.cellWidth / 2, surface.width - surface.cellWidth)),
                            Math.max(0, Math.min(drop.y - surface.cellHeight / 2, surface.height - surface.cellHeight)));
                    }
                }
                Repeater {
                    id: icons
                    model: DesktopService.entries
                    delegate: Rectangle {
                        id: icon
                        required property var modelData
                        required property int index
                        objectName: "desktopEntry:" + modelData.name
                        width: surface.cellWidth
                        height: surface.cellHeight
                        radius: Appearance.px(10)
                        color: surface.selected.includes(modelData.name) ? Appearance.withAlpha(Appearance.primary, 0.24)
                            : pointer.containsMouse ? "#337f8faf" : "transparent"
                        border.color: surface.selected.includes(modelData.name) ? Appearance.primary : "transparent"

                        function beginRename() {
                            surface.renameField = inlineName;
                            inlineName.text = modelData.name;
                            inlineName.forceActiveFocus();
                            const dot = modelData.directory ? -1 : modelData.name.lastIndexOf(".");
                            inlineName.select(0, dot > 0 ? dot : modelData.name.length);
                        }
                        function place() {
                            if (pointer.drag.active || surface.moving)
                                return;
                            const position = DesktopService.positions[window.modelData.name]?.[modelData.name];
                            const px = position ? position.x : Math.floor(index / surface.rows) * width + 12;
                            const py = position ? position.y : (index % surface.rows) * height + 12;
                            x = Math.max(0, Math.min(px, surface.width - width));
                            y = Math.max(0, Math.min(py, surface.height - height));
                        }
                        onIndexChanged: place()
                        Component.onCompleted: {
                            place();
                            Qt.callLater(() => {
                                if (!DesktopService.positions[window.modelData.name]?.[modelData.name])
                                    DesktopService.move(modelData.name, window.modelData.name, x, y);
                            });
                        }
                        Connections {
                            target: DesktopService
                            function onPositionsChanged() { icon.place(); }
                        }
                        Connections {
                            target: surface
                            function onWidthChanged() { icon.place(); }
                            function onHeightChanged() { icon.place(); }
                        }
                        Image {
                            anchors.top: parent.top
                            anchors.topMargin: Appearance.px(8)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Appearance.px(60)
                            height: width
                            visible: thumbnail.status !== Image.Ready
                            source: Quickshell.iconPath(icon.modelData.icon || "text-x-generic", true)
                                || Qt.resolvedUrl("icons/" + (icon.modelData.kind || "file") + ".svg")
                            sourceSize.width: width
                            sourceSize.height: height
                        }
                        Image {
                            id: thumbnail
                            objectName: "desktopThumbnail"
                            anchors.top: parent.top
                            anchors.topMargin: Appearance.px(8)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Appearance.px(76)
                            height: Appearance.px(60)
                            source: icon.modelData.preview || ""
                            sourceSize.width: Math.round(width * window.screen.devicePixelRatio)
                            sourceSize.height: Math.round(height * window.screen.devicePixelRatio)
                            asynchronous: true
                            autoTransform: true
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }
                        AppText {
                            visible: icon.modelData.broken
                            x: Appearance.px(24)
                            y: Appearance.px(32)
                            text: "!"
                            color: icon.modelData.broken ? "#ff9a9a" : "white"
                            style: Text.Outline
                            styleColor: "#bb000000"
                            font.pixelSize: Appearance.px(20)
                        }
                        AppText {
                            anchors.top: parent.top
                            anchors.topMargin: Appearance.px(76)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - Appearance.px(8)
                            text: icon.modelData.name
                            visible: surface.renameName !== icon.modelData.name
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            color: "white"
                            style: Text.Outline
                            styleColor: "#aa000000"
                            font.pixelSize: Appearance.px(15)
                        }
                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            property real originX: 0
                            property real originY: 0
                            property real minX: 0
                            property real minY: 0
                            property real maxX: 0
                            property real maxY: 0
                            drag.target: pressedButtons & Qt.LeftButton ? icon : null
                            drag.minimumX: minX
                            drag.minimumY: minY
                            drag.maximumX: maxX
                            drag.maximumY: maxY
                            onPressed: mouse => {
                                if (surface.renameField)
                                    surface.renameField.commit();
                                if (mouse.button === Qt.RightButton) {
                                    surface.openContext(icon.modelData.name);
                                    return;
                                }
                                surface.choose(icon.modelData.name, mouse.modifiers);
                                surface.beginMove();
                                originX = icon.x;
                                originY = icon.y;
                                minX = 0; minY = 0;
                                maxX = Math.max(0, surface.width - icon.width);
                                maxY = Math.max(0, surface.height - icon.height);
                                for (const entry of surface.dragOrigins) {
                                    minX = Math.max(minX, originX - entry.x);
                                    minY = Math.max(minY, originY - entry.y);
                                    maxX = Math.min(maxX, originX + surface.width - entry.item.width - entry.x);
                                    maxY = Math.min(maxY, originY + surface.height - entry.item.height - entry.y);
                                }
                            }
                            onPositionChanged: {
                                if (drag.active)
                                    surface.moveGroup(icon, icon.x - originX, icon.y - originY);
                            }
                            onReleased: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    const dragged = surface.moving;
                                    surface.finishMove();
                                    if (!dragged && !(mouse.modifiers & Qt.ControlModifier))
                                        surface.selected = [icon.modelData.name];
                                }
                            }
                            onCanceled: surface.finishMove()
                            onDoubleClicked: mouse => {
                                if (mouse.button === Qt.LeftButton)
                                    DesktopService.open(icon.modelData.url);
                            }
                            StyledToolTip {
                                visible: pointer.containsMouse && !pointer.pressed && !surface.moving
                                    && !selectionMouse.selecting && !entryMenu.visible && !surface.renameName
                                text: icon.modelData.name
                                delay: 650
                                width: Math.min(implicitWidth, Appearance.px(360), surface.width)
                                showBelow: icon.y + icon.height + height + gap < surface.height
                                contentItem: AppText {
                                    text: icon.modelData.name
                                    color: Appearance.layer0Text
                                    font.pixelSize: Appearance.px(14)
                                    wrapMode: Text.WrapAnywhere
                                }
                            }
                        }
                        TextField {
                            id: inlineName
                            objectName: "desktopRenameInput"
                            z: 3
                            visible: surface.renameName === icon.modelData.name
                            readOnly: surface.renamePending
                            anchors.top: parent.top
                            anchors.topMargin: Appearance.px(72)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - Appearance.px(4)
                            padding: Appearance.px(5)
                            font.pixelSize: Appearance.px(15)
                            color: Appearance.layer0Text
                            selectionColor: Appearance.primaryContainer
                            selectedTextColor: Appearance.primaryContainerText
                            selectByMouse: true
                            horizontalAlignment: TextInput.AlignHCenter
                            background: Rectangle {
                                radius: Appearance.px(5)
                                color: Appearance.layer2
                                border.color: Appearance.primary
                            }
                            function commit() {
                                if (!visible || surface.renamePending)
                                    return;
                                if (text === icon.modelData.name) {
                                    surface.cancelRename();
                                    return;
                                }
                                const invalid = !text.trim() || text.startsWith(".")
                                    || /[\/\\\x00-\x1f\x7f]/.test(text);
                                const exists = DesktopService.entries.some(entry => entry.name === text);
                                if (invalid || exists) {
                                    DesktopService.error = I18n.tr(exists ? "desktopNameExists" : "desktopInvalidName");
                                    forceActiveFocus();
                                    return;
                                }
                                surface.renamePending = true;
                                DesktopService.renameLinks([{name: icon.modelData.name, newName: text}]);
                            }
                            onAccepted: commit()
                            Keys.onEscapePressed: event => {
                                surface.cancelRename();
                                event.accepted = true;
                            }
                            onActiveFocusChanged: {
                                if (!activeFocus && visible)
                                    commit();
                            }
                        }
                    }
                }
                DesktopMenu {
                    id: entryMenu
                    DesktopMenuItem {
                        text: I18n.tr("desktopOpen") + (surface.contextEntries.length > 1 ? " (" + surface.contextEntries.length + ")" : "")
                        onTriggered: {
                            for (const entry of surface.contextEntries)
                                DesktopService.open(entry.url);
                        }
                    }
                    DesktopMenuItem {
                        text: I18n.tr("desktopOpenContainingFolder")
                        visible: surface.contextEntries.length === 1
                        height: visible ? implicitHeight : 0
                        enabled: visible && !surface.contextEntries[0]?.broken
                        onTriggered: DesktopService.open(surface.contextEntries[0].parentUrl)
                    }
                    DesktopMenuItem {
                        text: I18n.tr("desktopRenameLinks")
                        visible: surface.contextEntries.length === 1
                        height: visible ? implicitHeight : 0
                        enabled: visible && surface.contextEntries[0]?.link === true
                        onTriggered: surface.showRename()
                    }
                    DesktopMenuItem {
                        text: I18n.tr("desktopRemoveLink")
                        enabled: surface.contextEntries.length > 0 && surface.contextEntries.every(entry => entry.link)
                        onTriggered: DesktopService.removeLinks(surface.contextEntries.map(entry => entry.name))
                    }
                }
                DesktopMenu {
                    id: desktopMenu
                    DesktopMenuItem {
                        text: I18n.tr("desktopAddFiles")
                        onTriggered: files.open()
                    }
                    DesktopMenuItem {
                        text: I18n.tr("desktopAddFolder")
                        onTriggered: folder.open()
                    }
                    MenuSeparator {
                        contentItem: Rectangle { implicitHeight: 1; color: Appearance.outline }
                    }
                    DesktopMenuItem {
                        text: I18n.tr("desktopOpenFolder")
                        onTriggered: DesktopService.open(DesktopService.directoryUrl)
                    }
                }
                Rectangle {
                    visible: DesktopService.error !== ""
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: Appearance.px(20)
                    width: Math.min(parent.width - 24, Appearance.px(560))
                    height: errorText.implicitHeight + 24
                    radius: 12
                    color: Appearance.layer2
                    AppText {
                        id: errorText
                        anchors.fill: parent
                        anchors.margins: 12
                        text: DesktopService.error
                        color: Appearance.layer0Text
                        wrapMode: Text.Wrap
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: DesktopService.error = ""
                    }
                }
                FileDialog {
                    id: files
                    title: I18n.tr("desktopAddFiles")
                    fileMode: FileDialog.OpenFiles
                    onAccepted: DesktopService.add(selectedFiles.map(url => String(url)))
                }
                FolderDialog {
                    id: folder
                    title: I18n.tr("desktopAddFolder")
                    onAccepted: DesktopService.add([String(selectedFolder)])
                }

            }
        }
    }
}
