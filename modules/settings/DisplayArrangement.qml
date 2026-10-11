pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: root

    implicitHeight: Appearance.px(285)
    radius: Appearance.normalRadius
    color: SettingsPalette.layer3
    border.width: 1
    border.color: SettingsPalette.outline

    property var screens: []
    property bool dragging: false
    property string selectedName: ""
    property real minX: 0
    property real minY: 0
    property real spanWidth: 1
    property real spanHeight: 1
    readonly property real zoom: Math.min(
        (stage.width - Appearance.px(100)) / spanWidth,
        (stage.height - Appearance.px(60)) / spanHeight)
    readonly property real originX: (stage.width - spanWidth * zoom) / 2
    readonly property real originY: (stage.height - spanHeight * zoom) / 2

    function rebuild() {
        if (dragging)
            return;
        const next = OutputService.outputs.filter(output => output.enabled);
        if (next.length) {
            minX = Math.min(...next.map(output => output.x));
            minY = Math.min(...next.map(output => output.y));
            spanWidth = Math.max(1, Math.max(...next.map(output =>
                output.x + output.logicalWidth)) - minX);
            spanHeight = Math.max(1, Math.max(...next.map(output =>
                output.y + output.logicalHeight)) - minY);
        }
        screens = next;
    }

    function drop(output, px, py) {
        const x = minX + (px - originX) / zoom;
        const y = minY + (py - originY) / zoom;
        const w = output.logicalWidth;
        const h = output.logicalHeight;
        const others = screens.filter(item => item.name !== output.name);
        let best = null;
        let distance = Infinity;
        for (const other of others) {
            const ow = other.logicalWidth;
            const oh = other.logicalHeight;
            // Keep shared edges reachable and snap nearby top/centre/bottom
            // alignments. Positions use logical pixels (scale and rotation).
            let alignedY = Math.max(other.y - h + 1,
                Math.min(other.y + oh - 1, y));
            let alignedX = Math.max(other.x - w + 1,
                Math.min(other.x + ow - 1, x));
            for (const target of [other.y, other.y + (oh - h) / 2,
                    other.y + oh - h]) {
                if (Math.abs(alignedY - target) * zoom < Appearance.px(12))
                    alignedY = target;
            }
            for (const target of [other.x, other.x + (ow - w) / 2,
                    other.x + ow - w]) {
                if (Math.abs(alignedX - target) * zoom < Appearance.px(12))
                    alignedX = target;
            }
            const candidates = [
                { x: other.x - w, y: alignedY },
                { x: other.x + ow, y: alignedY },
                { x: alignedX, y: other.y - h },
                { x: alignedX, y: other.y + oh }
            ];
            for (const candidate of candidates) {
                if (others.some(item => candidate.x < item.x + item.logicalWidth
                        && candidate.x + w > item.x
                        && candidate.y < item.y + item.logicalHeight
                        && candidate.y + h > item.y))
                    continue;
                const d = Math.pow(candidate.x - x, 2)
                    + Math.pow(candidate.y - y, 2);
                if (d < distance) {
                    best = candidate;
                    distance = d;
                }
            }
        }
        if (best) {
            OutputService.moveOutput(output.name, best.x, best.y);
            screens = screens.map(item => item.name === output.name
                ? Object.assign({}, item, best) : item);
        }
        return best !== null;
    }

    Component.onCompleted: rebuild()
    Connections {
        target: OutputService
        function onOutputsChanged() { root.rebuild(); }
        function onApplyFinished(success, message) {
            if (!success)
                root.rebuild();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.panelPadding
        spacing: Appearance.spacingSmall

        AppText {
            text: I18n.tr("displayPosition")
            color: SettingsPalette.layer0Text
        }
        AppText {
            Layout.fillWidth: true
            text: I18n.tr("displayDragHint")
            color: SettingsPalette.subtext
            font.pixelSize: Appearance.smallFontSize
            wrapMode: Text.WordWrap
        }
        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Repeater {
                model: root.screens
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    property real dragX: 0
                    property real dragY: 0
                    x: pointer.pressed ? dragX
                        : root.originX + (modelData.x - root.minX) * root.zoom
                    y: pointer.pressed ? dragY
                        : root.originY + (modelData.y - root.minY) * root.zoom
                    width: modelData.logicalWidth * root.zoom
                    height: modelData.logicalHeight * root.zoom
                    z: pointer.pressed ? 2 : 0
                    radius: Appearance.smallRadius
                    color: root.selectedName === modelData.name || pointer.pressed
                        ? SettingsPalette.primaryContainer : SettingsPalette.layer1
                    border.width: 2
                    border.color: root.selectedName === modelData.name
                        ? SettingsPalette.primary : SettingsPalette.outline
                    clip: true

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Appearance.px(8)
                        AppText {
                            width: parent.width
                            text: tile.index + 1
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Appearance.px(26)
                            color: SettingsPalette.layer0Text
                        }
                        AppText {
                            width: parent.width
                            text: tile.modelData.name
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            color: SettingsPalette.layer0Text
                        }
                    }
                    MouseArea {
                        id: pointer
                        anchors.fill: parent
                        enabled: !OutputService.applying
                            && !OutputService.recovering
                            && OutputService.persistenceReady
                            && root.screens.length > 1
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        preventStealing: true
                        property point start
                        property point initial
                        onPressed: mouse => {
                            root.dragging = true;
                            root.selectedName = tile.modelData.name;
                            tile.dragX = root.originX
                                + (tile.modelData.x - root.minX) * root.zoom;
                            tile.dragY = root.originY
                                + (tile.modelData.y - root.minY) * root.zoom;
                            start = mapToItem(stage, mouse.x, mouse.y);
                            initial = Qt.point(tile.dragX, tile.dragY);
                        }
                        onPositionChanged: mouse => {
                            if (!pressed)
                                return;
                            const point = mapToItem(stage, mouse.x, mouse.y);
                            tile.dragX = initial.x + point.x - start.x;
                            tile.dragY = initial.y + point.y - start.y;
                        }
                        onReleased: {
                            const output = tile.modelData;
                            const x = tile.dragX;
                            const y = tile.dragY;
                            const moved = Math.abs(x - initial.x)
                                + Math.abs(y - initial.y) > 3;
                            root.dragging = false;
                            if (!moved || !root.drop(output, x, y))
                                root.rebuild();
                        }
                        onCanceled: {
                            root.dragging = false;
                            root.rebuild();
                        }
                    }
                }
            }
        }
    }
}
