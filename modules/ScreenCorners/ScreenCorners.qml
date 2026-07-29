import QtQuick
import Quickshell
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    anchors.fill: parent

    Item {
        id: topCorners

        anchors {
            left: parent.left
            right: parent.right
        }
        height: Appearance.cornerSize
        y: (-Appearance.barHeight - Appearance.cornerSize)
            * NiriService.overviewProgress

        RoundCorner {
            implicitSize: Appearance.cornerSize
            color: Appearance.barBgColor
            corner: RoundCorner.CornerEnum.TopLeft
            anchors {
                left: parent.left
                top: parent.top
            }
        }

        RoundCorner {
            implicitSize: Appearance.cornerSize
            color: Appearance.barBgColor
            corner: RoundCorner.CornerEnum.TopRight
            anchors {
                right: parent.right
                top: parent.top
            }
        }
    }

    RoundCorner {
        implicitSize: Appearance.cornerSize
        color: Appearance.barBgColor
        corner: RoundCorner.CornerEnum.BottomLeft
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
    }

    RoundCorner {
        implicitSize: Appearance.cornerSize
        color: Appearance.barBgColor
        corner: RoundCorner.CornerEnum.BottomRight
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
    }
}
