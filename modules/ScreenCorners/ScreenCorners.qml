import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    required property string outputName
    readonly property bool outputFullscreen:
        NiriService.outputActiveWindowIsFullscreen(
            outputName, width, height)

    anchors.fill: parent
    // A fullscreen client hides the decorative corners, but Launchpad is a
    // shell surface rather than that client and should keep the screen frame.
    visible: !outputFullscreen || NiriService.launchpadProgress > 0

    component ScreenCorner: Item {
        id: screenCorner

        property var corner: RoundCorner.CornerEnum.TopLeft
        property bool showShadow: true

        implicitWidth: Appearance.cornerSize
        implicitHeight: Appearance.cornerSize

        MultiEffect {
            anchors.fill: cornerFill
            z: 0
            visible: screenCorner.showShadow
                && ShellSettings.shadowEnabled
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
            color: ShellSettings.screenCornerColor
            corner: screenCorner.corner
        }
    }

    Item {
        id: topCorners

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: Appearance.cornerSize

        ScreenCorner {
            corner: RoundCorner.CornerEnum.TopLeft
            showShadow: false
            anchors {
                left: parent.left
                top: parent.top
            }
        }

        ScreenCorner {
            corner: RoundCorner.CornerEnum.TopRight
            showShadow: false
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
