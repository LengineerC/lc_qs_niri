pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.common.widgets
import qs.services

Rectangle {
    id: root

    required property var notificationEntry
    property bool historical: false

    signal activated
    signal secondaryAction

    implicitHeight: contentLayout.implicitHeight + Appearance.px(20)
    radius: Appearance.smallRadius
    color: cardArea.containsMouse
        ? Appearance.barLayer1Hover : Appearance.barLayer1
    border.width: historical ? 1 : 2
    border.color: historical
        ? Appearance.barOutline : Appearance.barPrimary

    function timeText() {
        const date = new Date(notificationEntry.timestamp);
        const elapsed = Math.max(0, Date.now() - date.getTime());
        const minutes = Math.floor(elapsed / 60000);
        if (minutes < 1)
            return I18n.tr("justNow");
        if (minutes < 60)
            return I18n.tr("minutesAgo").arg(minutes);
        if (minutes < 1440)
            return I18n.tr("hoursAgo").arg(Math.floor(minutes / 60));
        return I18n.locale.toString(date, "MM-dd HH:mm");
    }

    MouseArea {
        id: cardArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    RowLayout {
        id: contentLayout
        anchors {
            fill: parent
            margins: Appearance.px(10)
        }
        spacing: Appearance.px(10)

        NotificationAvatar {
            Layout.alignment: Qt.AlignTop
            implicitSize: Appearance.px(42)
            notificationEntry: root.notificationEntry
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(2)

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(6)

                Text {
                    Layout.fillWidth: true
                    text: root.notificationEntry.appName
                        || I18n.tr("unknownApplication")
                    color: Appearance.barSubtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                Text {
                    text: root.timeText()
                    color: Appearance.barSubtext
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.notificationEntry.summary
                    || I18n.tr("notification")
                color: Appearance.barLayer0Text
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.fontSize
                    weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.notificationEntry.body
                color: Appearance.barLayer1Text
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: Appearance.px(27)
            implicitHeight: Appearance.px(27)
            radius: Appearance.fullRadius
            color: actionArea.containsMouse
                ? Appearance.barLayer1Active : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.historical ? "󰆴" : "󰄬"
                color: root.historical
                    ? Appearance.barError : Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(14)
                }
            }

            MouseArea {
                id: actionArea
                anchors.fill: parent
                z: 2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.secondaryAction()
            }
        }
    }

    Behavior on color {
        ColorAnimation { duration: Appearance.fastDuration }
    }
}
