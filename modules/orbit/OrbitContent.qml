pragma ComponentBehavior: Bound
// Nyxuri Orbit design/physics port. See NOTICE.md (GPL-3.0).
import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import qs.common
import qs.services
import "OrbitMath.js" as OrbitMath

FocusScope {
    id: root
    property var items: OrbitService.items
    property var stack: []
    property var menuPath: []
    property int activeIndex: -1
    property bool searchMode: false
    property int engineIndex: 0
    readonly property var engines: [
        {name: "Bing", url: "https://www.bing.com/search?q="},
        {name: "Google", url: "https://www.google.com/search?q="},
        {name: "DeepSeek", url: "https://chat.deepseek.com/?q="},
        {name: "ChatGPT", url: "https://chatgpt.com/?q="}
    ]
    property var entry: OrbitMath.spring(0, 14, 0.70)
    property var transition: OrbitMath.spring(1, 15, 0.80)
    property var coreX: OrbitMath.spring(0, 18, 1)
    property var coreY: OrbitMath.spring(0, 18, 1)
    property var nodes: []
    property int frame: 0
    property bool animating: false
    property bool closing: false
    // Keep placement reactive: layer-shell gives us the final size only after
    // mapping the window. Never freeze coordinates calculated at 0 x 0.
    property real requestedX: -1
    property real requestedY: -1
    property bool anchorPending: false
    readonly property real centerX: Math.max(400 * fit,
        Math.min(width - 400 * fit, requestedX < 0 ? width / 2 : requestedX))
    readonly property real centerY: Math.max(330 * fit,
        Math.min(height - 330 * fit, requestedY < 0 ? height / 2 : requestedY))
    readonly property real unit: Appearance.px(1)
    readonly property real fit: Math.min(unit, width / 800, height / 660)
    readonly property real radius: Math.max(168, 120 + items.length * 12)
    readonly property real progress: { frame; return Math.max(0, Math.min(1, entry.current)); }
    readonly property color accent: Appearance.primary
    signal finished()

    function wake() { animating = true; }
    function tier(next, entering) {
        items = next;
        nodes = next.map(() => OrbitMath.spring(0, 12, 0.65));
        activeIndex = -1;
        transition.current = entering ? 0.65 : 1.16;
        transition.velocity = 0;
        transition.target = 1;
        transition.omega = entering ? 15 : 16;
        transition.zeta = entering ? 0.80 : 0.90;
        wake();
    }
    function openAt(x, y) {
        closing = false;
        searchMode = false;
        query.text = "";
        stack = [];
        menuPath = [];
        requestedX = Number.isFinite(x) ? x : -1;
        requestedY = Number.isFinite(y) ? y : -1;
        anchorPending = requestedX < 0 || requestedY < 0;
        entry.current = 0;
        entry.velocity = 0;
        entry.target = 1;
        tier(OrbitService.items, true);
        transition.current = 1;
        forceActiveFocus();
        if (pointer.containsMouse)
            captureAnchor(pointer.mouseX, pointer.mouseY);
    }
    function close() { closing = true; entry.target = 0; wake(); }
    function back() {
        if (searchMode) { searchMode = false; query.text = ""; forceActiveFocus(); return; }
        if (stack.length) {
            const previous = stack.slice();
            const parentItems = previous.pop();
            stack = previous;
            menuPath = menuPath.slice(0, -1);
            tier(parentItems, false);
        } else OrbitService.close();
    }
    function trigger(index) {
        if (closing) return;
        if (index < 0 || index >= items.length) {
            if (stack.length) back();
            else { searchMode = true; query.forceActiveFocus(); }
            return;
        }
        const item = items[index];
        if (item.children) { stack = stack.concat([items]); menuPath = menuPath.concat([index]); tier(item.children, true); }
        else OrbitService.execute(item);
    }
    function captureAnchor(x, y) {
        if (!anchorPending || width <= 0 || height <= 0 || !Number.isFinite(x) || !Number.isFinite(y))
            return;
        requestedX = x;
        requestedY = y;
        anchorPending = false;
    }
    function movePointer(x, y) {
        if (closing || searchMode || fit <= 0) return;
        captureAnchor(x, y);
        const next = OrbitMath.sector((x - centerX) / fit, (y - centerY) / fit, items.length, activeIndex);
        if (next !== activeIndex) { activeIndex = next; wake(); }
    }
    function cycle(step) {
        if (!items.length) return;
        activeIndex = (activeIndex + step + items.length) % items.length;
        wake();
    }
    function search() {
        if (!query.text.trim()) return;
        Qt.openUrlExternally(engines[engineIndex].url + encodeURIComponent(query.text.trim()));
        OrbitService.close();
    }
    Keys.onPressed: event => {
        event.accepted = true;
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace) back();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) trigger(activeIndex);
        else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_8) trigger(event.key - Qt.Key_1);
        else if (event.key === Qt.Key_Tab) cycle(event.modifiers & Qt.ShiftModifier ? -1 : 1);
        else if ([Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
            const direction = event.key === Qt.Key_Left ? [-100, 0] : event.key === Qt.Key_Right ? [100, 0]
                : event.key === Qt.Key_Up ? [0, -100] : [0, 100];
            activeIndex = OrbitMath.sector(direction[0], direction[1], items.length, -1); wake();
        } else if (event.text && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            searchMode = true; query.text += event.text; query.forceActiveFocus();
        } else event.accepted = false;
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Meta && activeIndex >= 0) { trigger(activeIndex); event.accepted = true; }
    }
    FrameAnimation {
        running: root.visible && root.animating
        onTriggered: {
            const dt = frameTime;
            let moving = OrbitMath.update(root.entry, dt);
            moving = OrbitMath.update(root.transition, dt) || moving;
            for (let i = 0; i < root.nodes.length; ++i) {
                root.nodes[i].target = !root.closing && root.activeIndex === i ? 1 : 0;
                moving = OrbitMath.update(root.nodes[i], dt) || moving;
            }
            const angle = OrbitMath.angle(root.activeIndex, root.items.length);
            root.coreX.target = root.activeIndex < 0 ? 0 : Math.cos(angle) * 10;
            root.coreY.target = root.activeIndex < 0 ? 0 : Math.sin(angle) * 10;
            moving = OrbitMath.update(root.coreX, dt) || moving;
            moving = OrbitMath.update(root.coreY, dt) || moving;
            ++root.frame;
            track.requestPaint();
            root.animating = moving;
            if (root.closing && root.progress < 0.02) { root.animating = false; root.finished(); }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Appearance.withAlpha(Appearance.layer0, (Theme.darkMode ? 0.42 : 0.22) * root.progress)
    }
    Item {
        id: ring
        x: root.centerX - width / 2
        y: root.centerY - height / 2
        width: 800
        height: 660
        scale: { root.frame; return root.fit * (0.76 + 0.24 * root.progress) * Math.max(0.2, root.transition.current); }
        opacity: root.searchMode ? 0 : root.progress
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Canvas {
            id: track
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2, cy = height / 2, r = root.radius;
                function color(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
                function arc(radius, from, to, lineWidth, tint, alpha) {
                    ctx.beginPath(); ctx.arc(cx, cy, radius, from, to);
                    ctx.lineWidth = lineWidth; ctx.strokeStyle = color(tint, alpha); ctx.stroke();
                }
                arc(r, 0, Math.PI * 2, 18, root.accent, 0.06);
                arc(r, 0, Math.PI * 2, 1, Appearance.outline, 0.10);
                ctx.setLineDash([3, 7]); arc(r, 0, Math.PI * 2, 1.2, Appearance.outline, 0.18);
                ctx.setLineDash([2, 4]); arc(48, 0, Math.PI * 2, 0.8, Appearance.outline, 0.12);
                ctx.setLineDash([]);
                const step = Math.PI * 2 / root.items.length;
                for (let i = 0; i < root.items.length; ++i) {
                    const angle = OrbitMath.angle(i, root.items.length), divider = angle + step / 2;
                    ctx.beginPath();
                    ctx.moveTo(cx + (r - 6) * Math.cos(divider), cy + (r - 6) * Math.sin(divider));
                    ctx.lineTo(cx + (r + 6) * Math.cos(divider), cy + (r + 6) * Math.sin(divider));
                    ctx.lineWidth = 1; ctx.strokeStyle = color(Appearance.outline, 0.16); ctx.stroke();
                    const p = Math.max(0, Math.min(1, root.nodes[i]?.current || 0));
                    if (p < 0.01) continue;
                    const half = step / 2 - Math.PI / 45;
                    arc(r, angle - half, angle + half, 14, root.accent, 0.15 * p);
                    arc(r, angle - half, angle + half, 2.5 + p * 1.5, root.accent, 0.95 * p);
                    ctx.setLineDash([2, 5]); ctx.beginPath();
                    ctx.moveTo(cx + root.coreX.current, cy + root.coreY.current);
                    ctx.lineTo(cx + (r + p * 16) * Math.cos(angle), cy + (r + p * 16) * Math.sin(angle));
                    ctx.lineWidth = 1.2 + p * 0.8; ctx.strokeStyle = color(root.accent, 0.8 * p); ctx.stroke();
                    ctx.setLineDash([]);
                }
            }
        }
        Item {
            x: { root.frame; return ring.width / 2 + root.coreX.current; }
            y: { root.frame; return ring.height / 2 + root.coreY.current; }
            Rectangle { x: -14; y: -14; width: 28; height: 28; radius: 14; color: Appearance.withAlpha(root.accent, 0.22) }
            Rectangle { visible: !root.stack.length; x: -8; y: -8; width: 16; height: 16; radius: 8; color: "transparent"; border.color: root.accent; border.width: 1.4 }
            Rectangle { visible: !root.stack.length; x: -3.2; y: -3.2; width: 6.4; height: 6.4; radius: 3.2; color: root.accent }
            // Vector chevron: no font bearings or concentric circle behind it.
            Canvas {
                visible: root.stack.length > 0
                x: -9; y: -9; width: 18; height: 18
                property color ink: Appearance.layer0Text
                onInkChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"); ctx.reset();
                    ctx.strokeStyle = ink; ctx.lineWidth = 2; ctx.lineCap = "round"; ctx.lineJoin = "round";
                    ctx.beginPath(); ctx.moveTo(11, 4); ctx.lineTo(6, 9); ctx.lineTo(11, 14); ctx.stroke();
                }
            }
        }
        Repeater {
            model: root.items
            delegate: Item {
                id: capsule
                required property var modelData
                required property int index
                readonly property real amount: { root.frame; return Math.max(0, Math.min(1, root.nodes[index]?.current || 0)); }
                readonly property real angle: OrbitMath.angle(index, root.items.length)
                width: Math.min(260, Math.max(156, Math.max(title.implicitWidth, subtitle.implicitWidth) + 94)) + amount * 24
                height: 48 + amount * 6
                x: ring.width / 2 + (root.radius + amount * 16) * Math.cos(angle) - width / 2
                y: ring.height / 2 + (root.radius + amount * 16) * Math.sin(angle) - height / 2
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1.5
                    anchors.bottomMargin: -1.5
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.10 + 0.12 * capsule.amount)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1
                        blurMax: 12
                        autoPaddingEnabled: true
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Appearance.mix(Appearance.layer2, root.accent, capsule.amount * 0.34)
                    border.color: Appearance.withAlpha(root.accent, 0.16 + capsule.amount * 0.74)
                    border.width: 1 + capsule.amount * 1.2
                }
                Rectangle {
                    x: parent.height / 2 - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30 + capsule.amount * 3; height: width; radius: width / 2
                    color: Appearance.withAlpha(root.accent, 0.10 + capsule.amount * 0.78)
                    AppText {
                        anchors.centerIn: parent
                        text: capsule.modelData.icon || "󰘳"
                        color: capsule.amount > 0.45 ? Appearance.layer0 : Appearance.layer0Text
                        font.family: Appearance.iconFontFamily
                        font.pixelSize: 20
                    }
                }
                Column {
                    x: 50
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    AppText { id: title; width: capsule.width - 90; elide: Text.ElideRight; text: capsule.modelData.name; color: Appearance.layer0Text; font.pixelSize: 15; font.weight: Font.DemiBold }
                    AppText { id: subtitle; width: capsule.width - 90; elide: Text.ElideRight; visible: capsule.amount > 0.18; opacity: (capsule.amount - 0.18) / 0.82; text: capsule.modelData.desc || ""; color: Appearance.layer1Text; font.pixelSize: 11 }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20; radius: 10
                    color: Appearance.withAlpha(Appearance.layer1Text, 0.12 + capsule.amount * 0.18)
                    AppText { anchors.centerIn: parent; text: capsule.index + 1; color: Appearance.layer1Text; font.pixelSize: 12 }
                }
            }
        }
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: root.captureAnchor(mouseX, mouseY)
        onPositionChanged: mouse => root.movePointer(mouse.x, mouse.y)
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) root.back();
            else root.movePointer(mouse.x, mouse.y);
        }
        onReleased: mouse => { if (mouse.button === Qt.LeftButton && !root.searchMode) root.trigger(root.activeIndex); }
        onWheel: wheel => root.cycle(wheel.angleDelta.y < 0 ? 1 : -1)
    }
    Rectangle {
        visible: root.searchMode
        x: Math.max(12, Math.min(root.width - width - 12, root.centerX - width / 2))
        y: root.centerY - height / 2
        width: Math.min(root.width - 24, Appearance.px(460))
        height: Appearance.px(96)
        radius: height / 3
        color: Appearance.layer2
        border.color: root.accent
        TextField {
            id: query
            x: 18; y: 10; width: parent.width - 36
            color: Appearance.layer0Text
            background: Item {}
            placeholderText: I18n.tr("orbitSearchPlaceholder")
            font.pixelSize: Appearance.px(18)
            onAccepted: root.search()
            Keys.onEscapePressed: root.back()
            Keys.onTabPressed: root.engineIndex = (root.engineIndex + 1) % root.engines.length
            Keys.onBacktabPressed: root.engineIndex = (root.engineIndex + root.engines.length - 1) % root.engines.length
        }
        AppText {
            x: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            text: root.engines[root.engineIndex].name + "   ·   " + I18n.tr("orbitSwitchSearchEngine")
            color: root.accent; font.pixelSize: Appearance.px(12)
        }
    }
}
