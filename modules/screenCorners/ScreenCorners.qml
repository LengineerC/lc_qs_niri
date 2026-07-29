import QtQuick
import Quickshell
import qs.common
import qs.common.widgets

Item {
    anchors.fill: parent

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
                color: Appearance.barBgColor
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
