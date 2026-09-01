pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    property bool visualizerActive: false
    property var visualizerPoints: []
    readonly property string cavaConfigPath: String(
        Qt.resolvedUrl("../../scripts/cava/raw_output_config.txt"))
            .replace(/^file:\/\//, "")

    implicitWidth: Appearance.px(570)
    implicitHeight: Math.min(Appearance.px(630),
        Appearance.px(72)
            + Math.max(Appearance.px(150),
                MediaService.players.length
                    * Appearance.px(194)))

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(9)

        PopupHeader {
            useBarPalette: true
            icon: "󰝚"
            iconSize: Appearance.px(22)
            title: I18n.tr("media")
            showActions: MediaService.players.length > 0
            dividerSpacing: Appearance.px(9)
            onCloseClicked: root.closeRequested()

            Text {
                text: MediaService.players.length
                    + " " + I18n.tr(
                        MediaService.players.length === 1
                            ? "mediaPlayer" : "mediaPlayers")
                color: Appearance.barSubtext
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                anchors.fill: parent
                visible: MediaService.players.length > 0
                contentWidth: width
                contentHeight: playerColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: playerColumn

                    width: parent.width
                    spacing: Appearance.px(10)

                    Repeater {
                        model: MediaService.players

                        delegate: MediaPlayerCard {
                            required property var modelData

                            Layout.fillWidth: true
                            player: modelData
                            visualizerPoints: root.visualizerPoints
                        }
                    }
                }

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: MediaService.players.length === 0
                spacing: Appearance.px(8)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰝛"
                    color: Appearance.barPrimary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(46)
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("noMediaPlaying")
                    color: Appearance.barLayer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.largeFontSize
                        weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("mprisPlayerHint")
                    color: Appearance.barSubtext
                    horizontalAlignment: Text.AlignHCenter
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }
        }
    }

    Process {
        id: cavaProcess

        running: root.visualizerActive && MediaService.players.some(
            player => player.isPlaying)
        command: ["cava", "-p", root.cavaConfigPath]

        onRunningChanged: {
            if (!running)
                root.visualizerPoints = [];
        }

        stdout: SplitParser {
            onRead: line => {
                root.visualizerPoints = line.split(";")
                    .map(value => value.trim())
                    .filter(value => value.length > 0)
                    .map(value => Number(value))
                    .filter(value => !isNaN(value));
            }
        }
    }
}
