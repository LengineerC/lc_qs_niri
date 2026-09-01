pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    required property string outputName
    readonly property bool shown:
        LeftSidebarService.shown
        && root.outputName.length > 0
        && LeftSidebarService.targetOutputName === root.outputName
    readonly property bool pointerInside: sidebarHover.hovered
    readonly property bool hostWindowActive: Window.active
    readonly property Item maskItem: root
    readonly property bool surfaceVisible:
        shown || x > hiddenX + 0.5
    readonly property real hiddenX:
        -width - Appearance.px(24)

    property bool editMode: false
    property Item draggedDelegate: null
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real dragPointerStartX: 0
    property real dragPointerStartY: 0
    property real dragViewportX: 0
    property real dragViewportY: 0
    property bool syncingModuleOrder: false

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

    function moduleSpan(moduleKey) {
        return moduleKey === "focusTimer" || moduleKey === "todo"
            ? 1 : 2;
    }

    function moduleComponent(moduleKey) {
        switch (moduleKey) {
        case "fastfetch":
            return fastfetchComponent;
        case "focusTimer":
            return focusTimerComponent;
        case "todo":
            return todoComponent;
        case "quickNote":
            return quickNoteComponent;
        case "dayProgress":
            return dayProgressComponent;
        default:
            return null;
        }
    }

    function rebuildModuleModel() {
        if (draggedDelegate)
            return;

        const order = ShellSettings.sanitizedSidebarModuleOrder(
            ShellSettings.sidebarModuleOrder);
        moduleModel.clear();
        for (const moduleKey of order) {
            moduleModel.append({
                moduleKey: moduleKey,
                span: moduleSpan(moduleKey)
            });
        }
    }

    function persistModuleOrder() {
        const order = [];
        for (let index = 0; index < moduleModel.count; ++index)
            order.push(moduleModel.get(index).moduleKey);

        syncingModuleOrder = true;
        ShellSettings.sidebarModuleOrder = order;
        syncingModuleOrder = false;
    }

    function beginModuleDrag(delegateItem, sourceIndex, localX, localY,
            viewportX, viewportY) {
        if (!editMode || !delegateItem)
            return;

        draggedDelegate = delegateItem;
        dragSourceIndex = sourceIndex;
        dragTargetIndex = sourceIndex;
        dragOffsetX = 0;
        dragOffsetY = 0;
        dragPointerStartX = delegateItem.x + localX;
        dragPointerStartY = delegateItem.y + localY;
        dragViewportX = viewportX;
        dragViewportY = viewportY;
    }

    function updateModuleDrag(delegateItem, viewportX, viewportY) {
        if (draggedDelegate !== delegateItem)
            return;

        dragViewportX = viewportX;
        dragViewportY = viewportY;
        updateModuleDragGeometry();
    }

    function updateModuleDragGeometry() {
        if (!draggedDelegate)
            return;

        const flickable = moduleScroll.contentItem;
        const contentY = flickable ? flickable.contentY : 0;
        const pointerX = dragViewportX;
        const pointerY = dragViewportY + contentY;
        dragOffsetX = pointerX - dragPointerStartX;
        dragOffsetY = pointerY - dragPointerStartY;
        let nearestIndex = dragSourceIndex;
        let nearestDistance = Number.POSITIVE_INFINITY;

        for (let index = 0; index < moduleRepeater.count; ++index) {
            const candidate = moduleRepeater.itemAt(index);
            if (!candidate)
                continue;

            const left = candidate.x;
            const right = candidate.x + candidate.width;
            const top = candidate.y;
            const bottom = candidate.y + candidate.height;
            const outsideX = pointerX < left
                ? left - pointerX
                : (pointerX > right ? pointerX - right : 0);
            const outsideY = pointerY < top
                ? top - pointerY
                : (pointerY > bottom ? pointerY - bottom : 0);
            const centerX = left + candidate.width / 2;
            const centerY = top + candidate.height / 2;
            const centerPenalty = (
                Math.abs(pointerX - centerX)
                    / Math.max(1, candidate.width)
                + Math.abs(pointerY - centerY)
                    / Math.max(1, candidate.height)) * 0.01;
            const distance = outsideX * outsideX
                + outsideY * outsideY + centerPenalty;

            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestIndex = index;
            }
        }
        dragTargetIndex = nearestIndex;
    }

    function finishModuleDrag(commit) {
        if (!draggedDelegate)
            return;

        const sourceIndex = dragSourceIndex;
        const targetIndex = dragTargetIndex;
        draggedDelegate = null;
        dragSourceIndex = -1;
        dragTargetIndex = -1;
        dragOffsetX = 0;
        dragOffsetY = 0;
        dragViewportX = 0;
        dragViewportY = 0;

        if (commit && sourceIndex >= 0 && targetIndex >= 0
                && sourceIndex !== targetIndex) {
            moduleModel.move(sourceIndex, targetIndex, 1);
            persistModuleOrder();
        }
    }

    x: shown ? Appearance.px(5) : hiddenX
    opacity: shown ? 1 : 0
    visible: surfaceVisible
    width: Math.min(Appearance.px(390),
        Math.max(Appearance.px(320),
            (parent?.width ?? Appearance.px(390)) * 0.32))

    focus: shown
    Keys.onEscapePressed: event => {
        if (root.editMode) {
            root.finishModuleDrag(false);
            root.editMode = false;
        } else {
            root.close();
        }
        event.accepted = true;
    }

    onShownChanged: {
        if (!shown) {
            finishModuleDrag(false);
            editMode = false;
        }
    }

    Component.onCompleted: rebuildModuleModel()

    Connections {
        target: ShellSettings

        function onReadyChanged() {
            if (ShellSettings.ready)
                root.rebuildModuleModel();
        }

        function onSidebarModuleOrderChanged() {
            if (!root.syncingModuleOrder)
                root.rebuildModuleModel();
        }
    }

    Timer {
        id: dragAutoScrollTimer

        interval: 16
        repeat: true
        running: root.draggedDelegate !== null
        onTriggered: {
            const flickable = moduleScroll.contentItem;
            if (!flickable)
                return;

            const edgeSize = Appearance.px(72);
            let velocity = 0;
            if (root.dragViewportY < edgeSize) {
                velocity = -Appearance.px(9)
                    * (1 - Math.max(0, root.dragViewportY)
                        / edgeSize);
            } else if (root.dragViewportY
                    > moduleScroll.height - edgeSize) {
                velocity = Appearance.px(9)
                    * (1 - Math.max(0,
                        moduleScroll.height - root.dragViewportY)
                        / edgeSize);
            }

            if (Math.abs(velocity) < 0.1)
                return;

            const maximum = Math.max(0,
                flickable.contentHeight - flickable.height);
            const nextPosition = Math.max(0,
                Math.min(maximum, flickable.contentY + velocity));
            if (Math.abs(nextPosition - flickable.contentY) < 0.01)
                return;

            flickable.contentY = nextPosition;
            root.updateModuleDragGeometry();
        }
    }

    HoverHandler {
        id: sidebarHover
    }

    ListModel {
        id: moduleModel
    }

    Component {
        id: fastfetchComponent
        FastfetchCard { useBarPalette: true }
    }

    Component {
        id: focusTimerComponent
        FocusTimerCard {}
    }

    Component {
        id: todoComponent
        TodoCard {}
    }

    Component {
        id: quickNoteComponent
        QuickNote {}
    }

    Component {
        id: dayProgressComponent
        DayProgressCard {
            active: root.shown
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.cornerSize
        color: ShellSettings.barFrostedGlass
            ? Appearance.barSurfaceColor : Appearance.barBgColor
        border.width: 1
        border.color: Appearance.barLayer0Border

        layer.enabled: ShellSettings.shadowEnabled
            && !ShellSettings.barFrostedGlass
        layer.effect: MultiEffect {
            shadowEnabled: ShellSettings.shadowEnabled
                && !ShellSettings.barFrostedGlass
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Appearance.barShadow, ShellSettings.shadowOpacity)
            shadowVerticalOffset: Math.round(
                ShellSettings.shadowOffsetY * Appearance.scale)
        }

        ClippingRectangle {
            anchors {
                fill: parent
                margins: Appearance.px(10)
            }
            radius: Math.max(0,
                Appearance.cornerSize - Appearance.px(10))
            color: "transparent"
            clip: true

            Controls.ScrollView {
                id: moduleScroll

                anchors.fill: parent
                clip: false
                contentWidth: availableWidth
                contentHeight: moduleGrid.implicitHeight

                Controls.ScrollBar.horizontal.policy:
                    Controls.ScrollBar.AlwaysOff
                Controls.ScrollBar.vertical.policy:
                    Controls.ScrollBar.AlwaysOff

                GridLayout {
                    id: moduleGrid

                    width: moduleScroll.availableWidth
                    columns: 2
                    columnSpacing: Appearance.px(10)
                    rowSpacing: Appearance.px(10)
                    uniformCellWidths: true

                    Repeater {
                        id: moduleRepeater
                        model: moduleModel

                        delegate: Item {
                            id: moduleDelegate

                        required property int index
                        required property string moduleKey
                        required property int span
                        readonly property bool dragging:
                            root.draggedDelegate === moduleDelegate
                        readonly property bool dropTarget:
                            root.draggedDelegate
                            && root.dragTargetIndex === index
                            && !dragging

                        Layout.fillWidth: true
                        Layout.columnSpan: span
                        Layout.preferredHeight: moduleLoader.item
                            ? moduleLoader.item.implicitHeight : 1
                        implicitHeight: Layout.preferredHeight
                        z: dragging ? 20 : 1
                        scale: dragging ? 0.935
                            : (root.editMode ? 0.985 : 1)

                        transform: Translate {
                            x: moduleDelegate.dragging
                                ? root.dragOffsetX : 0
                            y: moduleDelegate.dragging
                                ? root.dragOffsetY : 0
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Appearance.fastDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        SequentialAnimation on rotation {
                            running: root.editMode
                                && !moduleDelegate.dragging
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: -0.25
                                duration: 115 + moduleDelegate.index * 9
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 0.25
                                duration: 140 + moduleDelegate.index * 7
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 0
                                duration: 115 + moduleDelegate.index * 5
                                easing.type: Easing.InOutSine
                            }
                        }

                        Loader {
                            id: moduleLoader
                            anchors.fill: parent
                            sourceComponent:
                                root.moduleComponent(moduleDelegate.moduleKey)
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: root.editMode
                            radius: Appearance.px(24)
                            color: moduleDelegate.dragging
                                ? Appearance.withAlpha(
                                    Appearance.barPrimary, 0.08)
                                : "transparent"
                            border.width: moduleDelegate.dropTarget
                                ? Appearance.px(2) : 1
                            border.color: moduleDelegate.dropTarget
                                ? Appearance.barPrimary
                                : Appearance.withAlpha(
                                    Appearance.barPrimary, 0.34)

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: pressed
                                    ? Qt.ClosedHandCursor
                                    : Qt.OpenHandCursor

                                onPressed: mouse => {
                                    const viewportPosition = dragArea.mapToItem(
                                        moduleScroll, mouse.x, mouse.y);
                                    root.beginModuleDrag(
                                        moduleDelegate,
                                        moduleDelegate.index,
                                        mouse.x,
                                        mouse.y,
                                        viewportPosition.x,
                                        viewportPosition.y);
                                }

                                onPositionChanged: mouse => {
                                    if (pressed) {
                                        const viewportPosition =
                                            dragArea.mapToItem(
                                                moduleScroll,
                                                mouse.x,
                                                mouse.y);
                                        root.updateModuleDrag(
                                            moduleDelegate,
                                            viewportPosition.x,
                                            viewportPosition.y);
                                    }
                                }

                                onReleased: mouse => {
                                    const viewportPosition = dragArea.mapToItem(
                                        moduleScroll, mouse.x, mouse.y);
                                    root.updateModuleDrag(
                                        moduleDelegate,
                                        viewportPosition.x,
                                        viewportPosition.y);
                                    root.finishModuleDrag(true);
                                }

                                onCanceled: {
                                    root.finishModuleDrag(false);
                                }

                                onWheel: wheel => {
                                    const flickable = moduleScroll.contentItem;
                                    if (!flickable)
                                        return;
                                    const delta = wheel.angleDelta.y !== 0
                                        ? wheel.angleDelta.y
                                        : wheel.pixelDelta.y;
                                    const maximum = Math.max(0,
                                        flickable.contentHeight
                                            - flickable.height);
                                    flickable.contentY = Math.max(0,
                                        Math.min(maximum,
                                            flickable.contentY - delta));
                                    wheel.accepted = true;
                                }
                            }

                            Rectangle {
                                anchors {
                                    top: parent.top
                                    horizontalCenter: parent.horizontalCenter
                                    topMargin: Appearance.px(7)
                                }
                                width: Appearance.px(34)
                                height: Appearance.px(18)
                                radius: height / 2
                                color: Appearance.withAlpha(
                                    Appearance.barLayer0, 0.84)
                                border.width: 1
                                border.color: Appearance.withAlpha(
                                    Appearance.barPrimary, 0.45)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰇙"
                                    color: Appearance.barPrimary
                                    font {
                                        family: Appearance.iconFontFamily
                                        pixelSize: Appearance.px(13)
                                    }
                                }
                            }
                        }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: editButton

            anchors {
                top: parent.top
                right: parent.right
                margins: Appearance.px(14)
            }
            width: Appearance.px(32)
            height: width
            radius: width / 2
            z: 50
            color: root.editMode
                ? Appearance.barPrimaryContainer
                : Appearance.withAlpha(Appearance.barLayer0, 0.78)
            border.width: 1
            border.color: root.editMode
                ? Appearance.withAlpha(Appearance.barPrimary, 0.72)
                : Appearance.withAlpha(Appearance.barOutline, 0.42)
            opacity: root.editMode || editMouse.containsMouse ? 1 : 0.64

            Behavior on opacity {
                NumberAnimation { duration: Appearance.fastDuration }
            }

            Text {
                anchors.centerIn: parent
                text: root.editMode ? "󰄬" : "󰏫"
                color: root.editMode
                    ? Appearance.barPrimaryContainerText
                    : Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(16)
                }
            }

            MouseArea {
                id: editMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.finishModuleDrag(false);
                    root.editMode = !root.editMode;
                    root.forceActiveFocus();
                }

                StyledToolTip {
                    visible: editMouse.containsMouse
                    text: root.editMode
                        ? I18n.tr("finishEditing")
                        : I18n.tr("editWidgets")
                    delay: 450
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
