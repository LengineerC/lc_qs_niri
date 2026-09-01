pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.services

Item {
    id: root

    property string outputName: ""
    property Item activeItem: null
    property Item hoverItem: null
    property bool wheelLocked: false
    property Item draggedItem: null
    property int dragSourcePosition: -1
    property int dragTargetPosition: -1
    property real dragOffset: 0
    property int dragSourceWorkspaceIndex: -1
    property int dragTargetWorkspaceIndex: -1
    readonly property real padding: Appearance.px(5)
    readonly property string indicatorStyle:
        ShellSettings.workspaceIndicatorStyle
    readonly property bool dotIndicator: indicatorStyle === "dots"
    readonly property real delegateWidth: dotIndicator
        ? Appearance.px(22) : Appearance.px(26)
    readonly property real activeIndicatorWidth:
        indicatorStyle === "circle" ? Appearance.px(22)
        : Appearance.px(16)
    readonly property real activeIndicatorHeight:
        indicatorStyle === "circle" ? Appearance.px(22)
        : Appearance.px(7)

    implicitWidth: workspaceRow.implicitWidth + padding * 2
    implicitHeight: Appearance.barHeight

    function refreshActiveItem() {
        for (let index = 0; index < workspaceRepeater.count; ++index) {
            const item = workspaceRepeater.itemAt(index);
            if (item?.onThisOutput && item.workspaceActive) {
                activeItem = item;
                return;
            }
        }
        // Niri can deliver the old and new workspace role updates separately.
        // Keep the previous item for that event-loop turn instead of flashing.
    }

    function beginHover(item) {
        hoverClear.stop();
        hoverItem = item;
    }

    function endHover(item) {
        if (hoverItem === item)
            hoverClear.restart();
    }

    function visibleWorkspaceItems() {
        const items = [];
        for (let index = 0; index < workspaceRepeater.count; ++index) {
            const item = workspaceRepeater.itemAt(index);
            if (item?.onThisOutput && item.shouldShow)
                items.push(item);
        }
        return items;
    }

    function startWorkspaceDrag(item): void {
        const items = visibleWorkspaceItems();
        const position = items.indexOf(item);
        if (position < 0)
            return;

        hoverClear.stop();
        hoverItem = null;
        draggedItem = item;
        dragSourcePosition = position;
        dragTargetPosition = position;
        dragOffset = 0;
        dragSourceWorkspaceIndex = Number(item.model.index);
        dragTargetWorkspaceIndex = dragSourceWorkspaceIndex;
    }

    function updateWorkspaceDrag(item, translationX): void {
        if (draggedItem !== item)
            return;

        const items = visibleWorkspaceItems();
        if (items.length === 0)
            return;

        const first = items[0];
        const last = items[items.length - 1];
        const minimumOffset = first.x - item.x;
        const maximumOffset = last.x - item.x;
        dragOffset = Math.max(minimumOffset,
            Math.min(maximumOffset, Number(translationX)));

        const draggedCenter = item.x + item.width / 2 + dragOffset;
        let closestPosition = 0;
        let closestDistance = Number.POSITIVE_INFINITY;

        for (let position = 0; position < items.length; ++position) {
            const candidate = items[position];
            const candidateCenter = candidate.x + candidate.width / 2;
            const distance = Math.abs(draggedCenter - candidateCenter);
            if (distance < closestDistance) {
                closestDistance = distance;
                closestPosition = position;
            }
        }

        dragTargetPosition = closestPosition;
        dragTargetWorkspaceIndex = Number(
            items[closestPosition].model.index);
    }

    function workspaceDragShift(item): real {
        if (!draggedItem || item === draggedItem)
            return 0;

        const items = visibleWorkspaceItems();
        const position = items.indexOf(item);
        if (position < 0)
            return 0;

        if (dragTargetPosition > dragSourcePosition
                && position > dragSourcePosition
                && position <= dragTargetPosition) {
            return -draggedItem.width;
        }

        if (dragTargetPosition < dragSourcePosition
                && position >= dragTargetPosition
                && position < dragSourcePosition) {
            return draggedItem.width;
        }

        return 0;
    }

    function finishWorkspaceDrag(item): void {
        if (draggedItem !== item)
            return;

        const workspaceId = Number(item.model.id);
        const sourceIndex = dragSourceWorkspaceIndex;
        const targetIndex = dragTargetWorkspaceIndex;

        draggedItem = null;
        dragSourcePosition = -1;
        dragTargetPosition = -1;
        dragOffset = 0;
        dragSourceWorkspaceIndex = -1;
        dragTargetWorkspaceIndex = -1;

        if (sourceIndex > 0 && targetIndex > 0
                && sourceIndex !== targetIndex) {
            NiriService.moveWorkspaceToIndex(workspaceId, targetIndex);
        }
    }

    function switchRelative(direction) {
        if (wheelLocked || direction === 0)
            return;

        const outputWorkspaces = [];
        let activeIndex = -1;
        for (let index = 0; index < workspaceRepeater.count; ++index) {
            const item = workspaceRepeater.itemAt(index);
            if (!item?.onThisOutput)
                continue;

            if (item.workspaceActive)
                activeIndex = outputWorkspaces.length;
            outputWorkspaces.push(item);
        }

        const nextIndex = activeIndex + direction;
        if (activeIndex < 0 || nextIndex < 0
                || nextIndex >= outputWorkspaces.length)
            return;

        wheelLocked = true;
        wheelUnlock.restart();
        NiriService.focusWorkspaceById(
            outputWorkspaces[nextIndex].model.id);
    }

    onOutputNameChanged: activeRefresh.restart()

    Timer {
        id: activeRefresh

        interval: 0
        onTriggered: root.refreshActiveItem()
    }

    Timer {
        id: hoverClear

        interval: 0
        onTriggered: root.hoverItem = null
    }

    Timer {
        id: wheelUnlock

        interval: 120
        onTriggered: root.wheelLocked = false
    }

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.y !== 0
                ? event.angleDelta.y : event.pixelDelta.y;
            if (delta === 0)
                return;

            root.switchRelative(delta > 0 ? -1 : 1);
            event.accepted = true;
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: NiriService.toggleOverview()
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: Appearance.barLayer1
        border.width: 1
        border.color: Appearance.barLayer0Border
    }

    Item {
        id: content

        anchors {
            fill: parent
            margins: root.padding
        }

        Rectangle {
            id: activeIndicator

            z: 0
            visible: root.draggedItem === null
                && root.activeItem !== null && root.activeItem.visible
            x: root.activeItem
                ? workspaceRow.x + root.activeItem.x
                    + (root.activeItem.width - width) / 2
                : 0
            anchors.verticalCenter: parent.verticalCenter
            width: root.activeIndicatorWidth
            height: root.activeIndicatorHeight
            radius: Appearance.fullRadius
            color: root.indicatorStyle === "circle"
                ? Appearance.barSecondaryContainer : Appearance.barPrimary

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.spatialCurve
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Appearance.fastDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: hoverIndicator

            z: 0.5
            visible: root.draggedItem === null
                && root.hoverItem !== null && root.hoverItem.visible
            x: root.hoverItem
                ? workspaceRow.x + root.hoverItem.x
                    + (root.hoverItem.width - width) / 2
                : 0
            anchors.verticalCenter: parent.verticalCenter
            width: root.dotIndicator
                ? Appearance.px(20) : Appearance.px(22)
            height: root.dotIndicator
                ? Appearance.px(16) : Appearance.px(22)
            radius: Appearance.fullRadius
            color: root.dotIndicator && root.hoverItem?.selected
                ? Appearance.withAlpha(Appearance.barLayer0Text, 0.08)
                : root.hoverItem?.selected
                ? Appearance.mix(Appearance.barSecondaryContainer,
                    Appearance.barSecondaryContainerText, 0.12)
                : Appearance.barLayer1Hover
        }

        Row {
            id: workspaceRow

            z: 1
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                id: workspaceRepeater

                model: NiriService.workspaces
                onCountChanged: activeRefresh.restart()

                delegate: Item {
                    id: workspaceDelegate

                    required property var model
                    readonly property bool onThisOutput:
                        model.output === root.outputName
                    readonly property bool workspaceActive: model.isActive
                    readonly property bool workspaceEmpty:
                        Number(model.activeWindowId) === 0
                    readonly property bool shouldShow: onThisOutput
                        && (ShellSettings.showEmptyWorkspaces
                            || !workspaceEmpty || workspaceActive)
                    readonly property bool selected:
                        root.activeItem === workspaceDelegate
                    readonly property bool beingDragged:
                        root.draggedItem === workspaceDelegate
                    readonly property real dragShift:
                        root.workspaceDragShift(workspaceDelegate)

                    visible: shouldShow
                    width: shouldShow ? root.delegateWidth : 0
                    height: shouldShow ? Appearance.px(26) : 0
                    z: beingDragged ? 3 : 1
                    scale: beingDragged ? 1.13 : 1
                    opacity: beingDragged ? 0.92 : 1

                    transform: Translate {
                        x: workspaceDelegate.beingDragged
                            ? root.dragOffset : workspaceDelegate.dragShift

                        Behavior on x {
                            enabled: !workspaceDelegate.beingDragged
                            NumberAnimation {
                                duration: Appearance.fastDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                        }
                    }

                    onWorkspaceActiveChanged: activeRefresh.restart()
                    onOnThisOutputChanged: activeRefresh.restart()
                    onShouldShowChanged: activeRefresh.restart()
                    Component.onCompleted: activeRefresh.restart()

                    Rectangle {
                        id: dragBackground

                        anchors.centerIn: parent
                        width: root.indicatorStyle === "circle"
                            ? Appearance.px(22) : Appearance.px(20)
                        height: root.indicatorStyle === "circle"
                            ? Appearance.px(22) : Appearance.px(20)
                        radius: Appearance.fullRadius
                        color: workspaceDelegate.beingDragged
                            ? Appearance.barPrimaryContainer : "transparent"
                        border.width: root.indicatorStyle === "circle"
                                && workspaceDelegate.model.isUrgent ? 1 : 0
                        border.color: Appearance.barTertiary
                    }

                    Rectangle {
                        id: compactMarker

                        visible: root.dotIndicator
                        anchors.centerIn: parent
                        width: Appearance.px(6)
                        height: Appearance.px(6)
                        radius: Appearance.fullRadius
                        color: workspaceDelegate.model.isUrgent
                            ? Appearance.barTertiary
                            : workspaceDelegate.selected
                                    && !workspaceDelegate.beingDragged
                                ? "transparent"
                                    : workspaceDelegate.beingDragged
                                        ? Appearance.barPrimaryContainerText
                                        : Appearance.barSubtext

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fastDuration
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.dotIndicator
                        text: model.name || model.index
                        color: workspaceDelegate.selected
                            ? Appearance.barSecondaryContainerText
                            : model.isUrgent
                                ? Appearance.barTertiary : Appearance.barSubtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                            weight: workspaceDelegate.selected
                                ? Font.DemiBold : Font.Medium
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fastDuration
                            }
                        }
                    }

                    HoverHandler {
                        id: workspaceHover

                        enabled: workspaceDelegate.onThisOutput
                        cursorShape: workspaceDelegate.beingDragged
                            ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered)
                                root.beginHover(workspaceDelegate);
                            else
                                root.endHover(workspaceDelegate);
                        }
                    }

                    TapHandler {
                        enabled: workspaceDelegate.onThisOutput
                        acceptedButtons: Qt.LeftButton
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: {
                            NiriService.focusWorkspaceById(
                                workspaceDelegate.model.id);
                        }
                    }

                    DragHandler {
                        id: workspaceDrag

                        enabled: workspaceDelegate.onThisOutput
                        target: null
                        acceptedButtons: Qt.LeftButton
                        xAxis.enabled: true
                        yAxis.enabled: false
                        dragThreshold: Appearance.px(4)

                        onActiveChanged: {
                            if (active) {
                                root.startWorkspaceDrag(workspaceDelegate);
                                root.updateWorkspaceDrag(
                                    workspaceDelegate,
                                    activeTranslation.x);
                            } else {
                                root.finishWorkspaceDrag(workspaceDelegate);
                            }
                        }

                        onActiveTranslationChanged:
                            root.updateWorkspaceDrag(
                                workspaceDelegate,
                                activeTranslation.x)
                    }
                }
            }
        }
    }
}
