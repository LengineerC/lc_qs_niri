import Quickshell
import QtQuick
import qs.common
import qs.common.widgets

Item {
    anchors.fill: parent
    opacity: 0.75

    Loader {
        anchors.fill: parent

        sourceComponent: Item {
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
                //color: Appearance.barBgColor
                color: "#ff0000"
                corner: RoundCorner.CornerEnum.TopRight
                anchors {
                    right: parent.right
                    top: parent.top
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
    }
}
