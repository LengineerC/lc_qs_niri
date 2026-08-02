import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    anchors.fill: parent

    component ScreenCorner: Item {
        id: screenCorner

        property var corner: RoundCorner.CornerEnum.TopLeft

        implicitWidth: Appearance.cornerSize
        implicitHeight: Appearance.cornerSize

        MultiEffect {
            anchors.fill: cornerFill
            z: 0
            visible: ShellSettings.shadowEnabled
            source: cornerFill
            shadowEnabled: true
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(
                ShellSettings.shadowBlurRadius * Appearance.scale))
            shadowColor: Appearance.withAlpha(
                Theme.palette.m3shadow,
                Math.min(0.72, ShellSettings.shadowOpacity * 1.18))
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            autoPaddingEnabled: true
        }

        RoundCorner {
            id: cornerFill

            anchors.fill: parent
            z: 1
            implicitSize: Appearance.cornerSize
            color: Appearance.barBgColor
            corner: screenCorner.corner
        }
    }

    Item {
        id: topCorners

        anchors {
            left: parent.left
            right: parent.right
        }
        height: Appearance.cornerSize
        y: (-Appearance.barHeight - Appearance.cornerSize)
            * NiriService.overviewProgress

        ScreenCorner {
            corner: RoundCorner.CornerEnum.TopLeft
            anchors {
                left: parent.left
                top: parent.top
            }
        }

        ScreenCorner {
            corner: RoundCorner.CornerEnum.TopRight
            anchors {
                right: parent.right
                top: parent.top
            }
        }
    }

    ScreenCorner {
        corner: RoundCorner.CornerEnum.BottomLeft
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
    }

    ScreenCorner {
        corner: RoundCorner.CornerEnum.BottomRight
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
    }
}
