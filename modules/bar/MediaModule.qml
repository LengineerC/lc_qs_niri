pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

MouseArea {
    id: root

    property bool compact: false
    signal activated

    implicitWidth: Math.min(
        mediaRow.implicitWidth + Appearance.px(18),
        Appearance.px(compact ? 270 : 350))
    implicitHeight: Appearance.barHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

    onPressed: event => {
        if (event.button === Qt.LeftButton) {
            activated();
        } else if (event.button === Qt.MiddleButton) {
            MediaService.togglePlaying(MediaService.activePlayer);
        } else if (event.button === Qt.BackButton) {
            MediaService.previous(MediaService.activePlayer);
        } else if (event.button === Qt.RightButton
                || event.button === Qt.ForwardButton) {
            MediaService.next(MediaService.activePlayer);
        }
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: root.containsMouse
            ? Appearance.barLayer1Hover : Appearance.barLayer1
        border.width: 1
        border.color: Appearance.barLayer0Border

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation { duration: Appearance.fastDuration }
        }
    }

    RowLayout {
        id: mediaRow

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Appearance.px(9)
            rightMargin: Appearance.px(9)
        }
        spacing: Appearance.px(7)

        Item {
            implicitWidth: Appearance.px(23)
            implicitHeight: Appearance.px(23)

            Canvas {
                id: progressRing

                anchors.fill: parent
                antialiasing: true
                readonly property real value: MediaService.progress
                readonly property color trackColor:
                    Appearance.withAlpha(Appearance.barSubtext, 0.25)
                readonly property color progressColor: Appearance.barPrimary

                onValueChanged: requestPaint()
                onTrackColorChanged: requestPaint()
                onProgressColorChanged: requestPaint()
                onPaint: {
                    const context = getContext("2d");
                    const lineWidth = Appearance.px(2);
                    const center = width / 2;
                    const radius = Math.max(1, center - lineWidth);
                    context.clearRect(0, 0, width, height);
                    context.lineWidth = lineWidth;
                    context.lineCap = "round";

                    context.beginPath();
                    context.strokeStyle = trackColor;
                    context.arc(center, height / 2, radius,
                        0, Math.PI * 2);
                    context.stroke();

                    if (value > 0) {
                        context.beginPath();
                        context.strokeStyle = progressColor;
                        context.arc(center, height / 2, radius,
                            -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * value);
                        context.stroke();
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                text: MediaService.isPlaying ? "󰏤" : "󰝚"
                color: Appearance.barLayer0Text
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(13)
                }
            }
        }

        AppText {
            Layout.fillWidth: true
            Layout.maximumWidth: Appearance.px(root.compact ? 200 : 325)
            text: {
                const player = MediaService.activePlayer;
                const title = MediaService.cleanTitle(player?.trackTitle)
                    || I18n.tr("noMedia");
                return player?.trackArtist
                    ? title + "  •  " + player.trackArtist : title;
            }
            color: MediaService.available
                ? Appearance.barLayer0Text : Appearance.barSubtext
            elide: Text.ElideRight
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }
    }
}
