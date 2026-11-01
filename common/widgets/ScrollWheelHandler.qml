pragma ComponentBehavior: Bound

import QtQuick
import qs.common

WheelHandler {
    id: root

    required property Flickable flickable
    // ScrollView disables mouse dragging but must still accept wheel input.
    property bool allowNonInteractive: false
    parent: flickable
    target: null
    blocking: false // Let an outer scroll area handle input at our boundary.
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    acceptedModifiers: Qt.NoModifier
    enabled: flickable && (flickable.interactive || allowNonInteractive)

    property NumberAnimation scrollAnimation: NumberAnimation {
        target: root.flickable
        property: "contentY"
        duration: 120
        easing.type: Easing.OutCubic
    }

    onWheel: event => scroll(event)

    function scroll(event) {
        const pixels = event.pixelDelta.y;
        const delta = pixels !== 0
            ? pixels * Appearance.touchpadScrollMultiplier
            : event.angleDelta.y / 120 * 20 * Qt.styleHints.wheelScrollLines
                * Appearance.wheelScrollMultiplier;
        const minimum = flickable.originY - flickable.topMargin;
        const maximum = Math.max(minimum, flickable.originY + flickable.contentHeight
            - flickable.height + flickable.bottomMargin);
        const current = pixels === 0 && scrollAnimation.running
            ? scrollAnimation.to : flickable.contentY;
        const next = Math.max(minimum, Math.min(maximum, current - delta));
        if (delta === 0 || Math.abs(next - current) < 0.01) {
            event.accepted = false;
            return;
        }
        flickable.cancelFlick();
        scrollAnimation.stop();
        if (pixels !== 0) {
            flickable.contentY = next;
        } else {
            scrollAnimation.from = flickable.contentY;
            scrollAnimation.to = next;
            scrollAnimation.start();
        }
        event.accepted = true;
    }
}
