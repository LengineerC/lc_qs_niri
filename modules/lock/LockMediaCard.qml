pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.common
import qs.modules.bar
import qs.services

Rectangle {
    id: root

    readonly property var player: MediaService.activePlayer
    readonly property bool hasMedia: MediaService.available
    readonly property string artSource:
        MediaService.artSource(player)

    color: Appearance.barLayer2
    radius: Appearance.normalRadius
    border.width: 1
    border.color: Appearance.barOutline
    clip: true

    Image {
        id: cover

        anchors.fill: parent
        source: root.artSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: root.artSource !== ""
        opacity: status === Image.Ready ? 0.28 : 0

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.5
            blurMax: 32
        }

        Behavior on opacity {
            NumberAnimation { duration: Appearance.spatialDuration }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ShellSettings.barFrostedGlass
            ? Appearance.withAlpha(
                Appearance.barGlassBaseColor, 0.48)
            : Appearance.withAlpha(Appearance.barLayer2, 0.5)
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(15)

        Text {
            Layout.fillWidth: true
            text: I18n.tr("media")
            color: Appearance.barSubtext
            elide: Text.ElideRight
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            text: root.hasMedia
                ? MediaService.cleanTitle(
                    root.player?.trackTitle)
                    || I18n.tr("unknownTitle")
                : I18n.tr("noMedia")
            color: Appearance.barLayer0Text
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.largeFontSize
                weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.hasMedia
                ? String(root.player?.trackArtist
                    || I18n.tr("unknownArtist"))
                : I18n.tr("noMediaPlaying")
            color: Appearance.barSubtext
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.hasMedia
                && (root.player?.lengthSupported ?? false)
                && (root.player?.length ?? 0) > 0
            spacing: Appearance.px(7)

            Text {
                text: MediaService.formatTime(
                    lockSeekBar.displayValue
                        * Math.max(0, root.player?.length ?? 0))
                color: Appearance.barSubtext
                font {
                    family: Appearance.monospaceFontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }

            WavySeekBar {
                id: lockSeekBar

                useBarPalette: true
                Layout.fillWidth: true
                implicitHeight: Appearance.px(18)
                value: MediaService.ratioFor(root.player)
                playing: root.player?.isPlaying ?? false
                seekable: root.hasMedia
                    && (root.player?.canSeek ?? false)
                    && (root.player?.lengthSupported ?? false)
                    && (root.player?.length ?? 0) > 0
                onSeekRequested: ratio => {
                    if (root.player)
                        root.player.position = Math.max(0.1,
                            ratio * root.player.length);
                }
            }

            Text {
                text: MediaService.formatTime(
                    root.player?.length ?? 0)
                color: Appearance.barSubtext
                font {
                    family: Appearance.monospaceFontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.px(10)

            MediaButton {
                icon: "󰒮"
                enabled: root.hasMedia
                onClicked: MediaService.previous(root.player)
            }

            MediaButton {
                primary: true
                icon: MediaService.isPlaying ? "󰏤" : "󰐊"
                enabled: root.hasMedia
                onClicked: MediaService.togglePlaying(root.player)
            }

            MediaButton {
                icon: "󰒭"
                enabled: root.hasMedia
                onClicked: MediaService.next(root.player)
            }
        }

        Item { Layout.fillHeight: true }
    }

    component MediaButton: Rectangle {
        id: mediaButton

        required property string icon
        property bool primary: false
        signal clicked

        implicitWidth: primary
            ? Appearance.px(48) : Appearance.px(40)
        implicitHeight: Appearance.px(36)
        radius: Appearance.fullRadius
        color: primary
            ? Appearance.barPrimaryContainer
            : Appearance.barLayer3
        opacity: enabled ? 1 : 0.45
        scale: buttonArea.pressed ? 0.94 : 1

        Text {
            anchors.centerIn: parent
            text: mediaButton.icon
            color: mediaButton.primary
                ? Appearance.barPrimaryContainerText
                : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(17)
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            enabled: mediaButton.enabled
            cursorShape: enabled
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mediaButton.clicked()
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
