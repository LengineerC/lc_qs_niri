pragma ComponentBehavior: Bound

import QtQuick
import "../../Caelestia/Blobs" as Blobs
import "../../modules/bar/BarGeometry.js" as BarGeometry

// Loaded through a file URL, outside Quickshell's virtual qs: import tree.
// The parent Loader supplies reactive geometry and theme values.
Item {
    id: root
    readonly property var settings: parent
    readonly property matrix4x4 deformMatrix: popupShape.deformMatrix
    readonly property var popupGeometry: BarGeometry.blobPopupRect(root.settings.edge,
        root.settings.popupX, root.settings.popupY, root.settings.popupWidth, root.settings.popupHeight,
        root.settings.overlapHeight)
    signal backgroundClicked

    Blobs.BlobGroup {
        id: group
        color: root.settings.surfaceColor
        smoothing: root.settings.smoothing
    }

    Blobs.BlobRect {
        x: root.settings.barX
        y: root.settings.barY
        width: root.settings.barWidth
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
        x: root.popupGeometry.x
        y: root.popupGeometry.y
        width: visible ? root.popupGeometry.width : 0
        height: visible ? root.popupGeometry.height : 0
        radius: root.settings.popupRadius
        deformScale: 0.000002
    }
}
