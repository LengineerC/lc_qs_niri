pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common

ColumnLayout {
    id: root

    default property alias actions: actionRow.data

    signal closeClicked

    property string icon: ""
    property var iconSource: ""
    property string title: ""
    property string subtitle: ""

    property bool showActions: true
    property bool showCloseButton: false
    property bool showDivider: true

    property color iconColor: Appearance.primary
    property color titleColor: Appearance.layer0Text
    property color subtitleColor: Appearance.subtext
    property color dividerColor: Appearance.outline
    property real dividerOpacity: 0.55

    property int iconSize: Appearance.px(21)
    property int iconSlotSize: iconSize
    property int titleFontSize: Appearance.largeFontSize
    property int titleFontWeight: Font.DemiBold
    property int subtitleFontSize: Appearance.smallFontSize
    property real headerRowHeight: -1

    property real contentSpacing: Appearance.px(8)
    property real actionSpacing: Appearance.px(7)
    property real dividerSpacing: Appearance.px(8)
    property real contentLeftMargin: 0
    property real contentRightMargin: 0
    property real dividerLeftMargin: 0
    property real dividerRightMargin: 0

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: root.showDivider ? root.dividerSpacing : 0

    RowLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: root.headerRowHeight
        Layout.leftMargin: root.contentLeftMargin
        Layout.rightMargin: root.contentRightMargin
        spacing: root.contentSpacing

        Item {
            visible: root.icon.length > 0
                || String(root.iconSource).length > 0
            Layout.preferredWidth: root.iconSlotSize
            Layout.preferredHeight: root.iconSlotSize
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.centerIn: parent
                visible: String(root.iconSource).length > 0
                source: root.iconSource
                implicitSize: root.iconSize
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: String(root.iconSource).length === 0
                text: root.icon
                color: root.iconColor
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: root.iconSize
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.titleColor
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: root.titleFontSize
                    weight: root.titleFontWeight
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: root.subtitleColor
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: root.subtitleFontSize
                }
            }
        }

        RowLayout {
            id: actionRow

            visible: root.showActions && children.length > 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: root.actionSpacing
        }

        CloseButton {
            visible: root.showCloseButton
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onClicked: root.closeClicked()
        }
    }

    Rectangle {
        visible: root.showDivider
        Layout.fillWidth: true
        Layout.leftMargin: root.dividerLeftMargin
        Layout.rightMargin: root.dividerRightMargin
        implicitHeight: 1
        color: root.dividerColor
        opacity: root.dividerOpacity
    }
}
