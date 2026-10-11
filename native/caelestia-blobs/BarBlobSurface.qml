pragma ComponentBehavior: Bound

import QtQuick
import "../../Caelestia/Blobs" as Blobs

// Loaded through a file URL, outside Quickshell's virtual qs: import tree.
// The parent Loader supplies reactive geometry and theme values.
Item {
    id: root
    readonly property var settings: parent
    readonly property matrix4x4 deformMatrix: popupShape.deformMatrix
    signal backgroundClicked

    Blobs.BlobGroup {
        id: group
        color: root.settings.surfaceColor
        smoothing: root.settings.smoothing
    }

    Blobs.BlobRect {
        width: parent.width
        height: root.settings.barHeight
        group: group
        radius: 0
        deformScale: 0
        MouseArea {
            anchors.fill: parent
            onClicked: root.backgroundClicked()
        }
    }

    Blobs.BlobRect {
        id: popupShape
        visible: root.settings.popupVisible
        group: group
        x: root.settings.popupX
        y: root.settings.barHeight - root.settings.overlapHeight
        width: visible ? root.settings.popupWidth : 0
        height: visible
            ? root.settings.popupHeight + root.settings.overlapHeight : 0
        radius: root.settings.popupRadius
        deformScale: 0.000002
    }
}
