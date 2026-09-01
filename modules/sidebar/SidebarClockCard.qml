pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property date now: new Date()

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Appearance.px(28)
    radius: Appearance.smallRadius
    color: Appearance.barLayer3
    border.width: 1
    border.color: Appearance.barOutline

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    RowLayout {
        id: content

        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(12)

        Text {
            text: "󰥔"
            color: Appearance.barPrimary
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(28)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(1)

            Text {
                Layout.fillWidth: true
                text: I18n.locale.toString(
                    root.now, ShellSettings.timeFormat)
                color: Appearance.barLayer0Text
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(25)
                    weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                text: I18n.locale.toString(
                    root.now, ShellSettings.dateFormat)
                color: Appearance.barSubtext
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.fontSize
                }
            }
        }
    }
}
