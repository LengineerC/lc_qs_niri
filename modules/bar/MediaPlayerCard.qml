pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common
import qs.services

ClippingRectangle {
    id: root

    required property MprisPlayer player

    property var visualizerPoints: []
    readonly property real progress: seekBar.displayValue

    implicitHeight: Appearance.px(184)
    radius: Appearance.normalRadius
    color: ShellSettings.barFrostedGlass
        ? Appearance.withAlpha(Appearance.barGlassBaseColor, 0.36)
        : Appearance.barLayer1
    border.width: MediaService.activePlayer === player ? 2 : 1
    border.color: MediaService.activePlayer === player
        ? Appearance.barPrimary : Appearance.barOutline

    scale: 0.99

    Image {
        id: backgroundArt

        anchors.fill: parent
        source: MediaService.artSource(root.player)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: status === Image.Ready
            ? (ShellSettings.barFrostedGlass ? 0.12 : 0.22) : 0
        layer.enabled: opacity > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.8
            blurMax: Appearance.px(28)
            saturation: -0.25
        }

        Behavior on opacity {
            NumberAnimation { duration: Appearance.fastDuration }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ShellSettings.barFrostedGlass
            ? Appearance.withAlpha(Appearance.barGlassBaseColor, 0.18)
            : Appearance.withAlpha(Appearance.barLayer1, 0.72)
    }

    MediaWaveform {
        anchors.fill: parent
        points: root.visualizerPoints
        live: root.player.isPlaying
        waveColor: Appearance.barPrimary
    }

    MouseArea {
        anchors.fill: parent
        onClicked: MediaService.setActivePlayer(root.player)
    }

    RowLayout {
        anchors {
            fill: parent
            margins: Appearance.px(13)
        }
        spacing: Appearance.px(14)

        Rectangle {
            Layout.fillHeight: true
            implicitWidth: height
            radius: Appearance.smallRadius
            color: Appearance.barLayer3
            clip: true

            Image {
                id: coverArt

                anchors.fill: parent
                source: MediaService.artSource(root.player)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Text {
                anchors.centerIn: parent
                visible: coverArt.status !== Image.Ready
                text: "󰝚"
                color: Appearance.barPrimary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(45)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.px(2)

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(7)

                Text {
                    Layout.fillWidth: true
                    text: MediaService.cleanTitle(root.player.trackTitle)
                        || I18n.tr("unknownTitle")
                    color: Appearance.barLayer0Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.largeFontSize
                        weight: Font.DemiBold
                    }
                }

                Rectangle {
                    implicitWidth: Math.min(Appearance.px(130),
                        playerIdentity.implicitWidth + Appearance.px(12))
                    implicitHeight: Appearance.px(24)
                    radius: Appearance.fullRadius
                    color: MediaService.activePlayer === root.player
                        ? Appearance.barPrimaryContainer
                        : Appearance.barLayer1Active

                    Text {
                        id: playerIdentity

                        anchors {
                            fill: parent
                            leftMargin: Appearance.px(6)
                            rightMargin: Appearance.px(6)
                        }
                        text: root.player.identity
                            || I18n.tr("media")
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: MediaService.activePlayer === root.player
                            ? Appearance.barPrimaryContainerText
                            : Appearance.barSubtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.player.trackArtist
                    || I18n.tr("unknownArtist")
                color: Appearance.barLayer1Text
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.fontSize
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.player.trackAlbum
                color: Appearance.barSubtext
                elide: Text.ElideRight
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(8)

                Text {
                    text: MediaService.formatTime(
                        root.progress * Math.max(0, root.player.length))
                    color: Appearance.barSubtext
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }

                WavySeekBar {
                    useBarPalette: true
                    id: seekBar

                    Layout.fillWidth: true
                    implicitHeight: Appearance.px(18)
                    value: MediaService.ratioFor(root.player)
                    playing: root.player.isPlaying
                    seekable: root.player.canSeek
                        && root.player.lengthSupported
                        && root.player.length > 0
                    onSeekRequested: ratio => {
                        root.player.position = Math.max(0.1,
                            ratio * root.player.length);
                    }
                }

                Text {
                    text: MediaService.formatTime(root.player.length)
                    color: Appearance.barSubtext
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.px(4)
                spacing: Appearance.px(9)

                Item { Layout.fillWidth: true }

                ControlButton {
                    icon: "󰒮"
                    enabled: root.player.canGoPrevious
                    onClicked: MediaService.previous(root.player)
                }

                ControlButton {
                    primary: true
                    icon: root.player.isPlaying ? "󰏤" : "󰐊"
                    enabled: root.player.canTogglePlaying
                    onClicked: {
                        MediaService.setActivePlayer(root.player);
                        MediaService.togglePlaying(root.player);
                    }
                }

                ControlButton {
                    icon: "󰒭"
                    enabled: root.player.canGoNext
                    onClicked: MediaService.next(root.player)
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    component ControlButton: Rectangle {
        id: button

        required property string icon
        property bool primary: false
        signal clicked

        implicitWidth: Appearance.px(primary ? 42 : 30)
        implicitHeight: Appearance.px(primary ? 42 : 30)
        radius: primary
            ? (root.player.isPlaying
                ? Appearance.smallRadius : Appearance.fullRadius)
            : Appearance.fullRadius
        color: primary
            ? Appearance.barPrimaryContainer
            : buttonMouse.containsMouse
                ? Appearance.barLayer1Active
                : Appearance.withAlpha(Appearance.barLayer1Active, 0)
        scale: buttonMouse.pressed ? 0.88 : 1
        opacity: enabled ? 1 : 0.35

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: button.primary
                ? Appearance.barPrimaryContainerText
                : Appearance.barLayer0Text
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(button.primary ? 21 : 17)
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: enabled
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation { duration: Appearance.fastDuration }
        }

        Behavior on radius {
            NumberAnimation { duration: Appearance.fastDuration }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player.playbackState
            === MprisPlaybackState.Playing
        onTriggered: root.player.positionChanged()
    }
}
