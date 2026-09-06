pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    component PanelText: AppText {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component ModeButton: ChoiceChip {
        signal clicked
        onChosen: clicked()
    }

    readonly property var schemes: [
        {
            value: "scheme-content",
            key: "schemeContent"
        },
        {
            value: "scheme-expressive",
            key: "schemeExpressive"
        },
        {
            value: "scheme-fidelity",
            key: "schemeFidelity"
        },
        {
            value: "scheme-fruit-salad",
            key: "schemeFruitSalad"
        },
        {
            value: "scheme-monochrome",
            key: "schemeMonochrome"
        },
        {
            value: "scheme-neutral",
            key: "schemeNeutral"
        },
        {
            value: "scheme-rainbow",
            key: "schemeRainbow"
        },
        {
            value: "scheme-tonal-spot",
            key: "schemeTonalSpot"
        },
        {
            value: "scheme-vibrant",
            key: "schemeVibrant"
        }
    ]
    readonly property var wallpaperModes: [
        {
            value: "Stretch",
            key: "wallpaperStretch"
        },
        {
            value: "PreserveAspectFit",
            key: "wallpaperFit"
        },
        {
            value: "PreserveAspectCrop",
            key: "wallpaperFill"
        },
        {
            value: "Tile",
            key: "wallpaperTile"
        },
        {
            value: "TileVertically",
            key: "wallpaperVerticalTile"
        },
        {
            value: "TileHorizontally",
            key: "wallpaperHorizontalTile"
        },
        {
            value: "Pad",
            key: "wallpaperCover"
        }
    ]
    readonly property var wallpaperTransitions: [
        {
            value: "none",
            key: "wallpaperTransitionNone"
        },
        {
            value: "fade",
            key: "wallpaperTransitionFade"
        },
        {
            value: "wipe",
            key: "wallpaperTransitionWipe"
        },
        {
            value: "disc",
            key: "wallpaperTransitionDisc"
        },
        {
            value: "stripes",
            key: "wallpaperTransitionStripes"
        },
        {
            value: "iris",
            key: "wallpaperTransitionIris"
        },
        {
            value: "pixelate",
            key: "wallpaperTransitionPixelate"
        },
        {
            value: "portal",
            key: "wallpaperTransitionPortal"
        },
        {
            value: "random",
            key: "random"
        }
    ]

    FileDialog {
        id: wallpaperFileDialog
        title: I18n.tr("chooseWallpaper")
        currentFolder: WallpaperService.fileUrl(WallpaperService.directory)
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp)"]
        onAccepted: WallpaperService.apply(selectedFile)
    }

    FolderDialog {
        id: wallpaperFolderDialog
        title: I18n.tr("chooseWallpaperDirectory")
        currentFolder: WallpaperService.fileUrl(WallpaperService.directory)
        onAccepted: WallpaperService.setDirectory(selectedFolder)
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: forceActiveFocus()
        }

        SettingsPageHeader {
            id: stylePageHeader

            height: implicitHeight
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Appearance.pagePadding
            }
            icon: "󰏘"
            title: I18n.tr("style")
            onCloseClicked: root.closeRequested()

            PanelText {
                visible: Theme.generating
                text: I18n.tr("generating")
                color: Appearance.primary
                font.pixelSize: Appearance.smallFontSize
            }
        }

        Flickable {
            id: styleFlickable

            anchors {
                top: stylePageHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Appearance.px(5)
                leftMargin: Appearance.px(18)
                rightMargin: Appearance.px(10)
                bottomMargin: Appearance.px(14)
            }
            contentWidth: width
            contentHeight: styleColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: styleColumn

                width: styleFlickable.width - Appearance.px(10)
                spacing: Appearance.spacingMedium

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(205)
            radius: Appearance.normalRadius
            color: Appearance.layer1
            border.width: 1
            border.color: Appearance.outline
            clip: true

            Image {
                anchors.fill: parent
                source: WallpaperService.fileUrl(WallpaperService.currentPath)
                sourceSize.width: Math.max(1, Math.ceil(width * (Window.window?.devicePixelRatio ?? 1)))
                fillMode: WallpaperService.imageFillMode
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: Appearance.px(48)
                color: Appearance.withAlpha(Theme.palette.m3scrim, 0.62)

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.px(12)
                        rightMargin: Appearance.px(12)
                    }
                    spacing: Appearance.spacingSmall

                    PanelText {
                        Layout.fillWidth: true
                        text: WallpaperService.currentPath || I18n.tr("noWallpaperSelected")
                        color: "white"
                        elide: Text.ElideMiddle
                        font.pixelSize: Appearance.smallFontSize
                    }

                    ActionButton {
                        icon: "󰈔"
                        label: I18n.tr("chooseFile")
                        onClicked: wallpaperFileDialog.open()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingSmall

            ActionButton {
                icon: "󰒮"
                label: I18n.tr("previous")
                enabled: WallpaperService.wallpapers.length > 0
                opacity: enabled ? 1 : 0.4
                onClicked: WallpaperService.previous()
            }

            ActionButton {
                icon: "󰒝"
                label: I18n.tr("random")
                enabled: WallpaperService.wallpapers.length > 0
                opacity: enabled ? 1 : 0.4
                onClicked: WallpaperService.random()
            }

            ActionButton {
                icon: "󰒭"
                label: I18n.tr("next")
                enabled: WallpaperService.wallpapers.length > 0
                opacity: enabled ? 1 : 0.4
                onClicked: WallpaperService.next()
            }

            Item {
                Layout.fillWidth: true
            }

            ActionButton {
                icon: "󰉋"
                label: I18n.tr("wallpaperDirectory")
                onClicked: wallpaperFolderDialog.open()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingSmall

            PanelText {
                text: I18n.tr("wallpaperDisplayMode")
                color: Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacingSmall

                Repeater {
                    model: root.wallpaperModes

                    delegate: ModeButton {
                        required property var modelData

                        label: I18n.tr(modelData.key)
                        selected: ShellSettings.wallpaperFillMode === modelData.value
                        onClicked: ShellSettings.wallpaperFillMode = modelData.value
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingSmall

            PanelText {
                text: I18n.tr("wallpaperTransition")
                color: Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall

                Repeater {
                    model: root.wallpaperTransitions

                    delegate: ModeButton {
                        required property var modelData

                        label: I18n.tr(modelData.key)
                        selected: ShellSettings.wallpaperTransition === modelData.value
                        onClicked: ShellSettings.wallpaperTransition = modelData.value
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: launchpadBackgroundRow.implicitHeight
                + Appearance.px(20)
            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                id: launchpadBackgroundRow

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.spacingMedium
                }
                spacing: Appearance.spacingSmall

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PanelText {
                        text: I18n.tr("launchpadBackground")
                        color: Appearance.layer0Text
                    }

                    PanelText {
                        text: I18n.tr("launchpadBackgroundHint")
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }
                }

                ModeButton {
                    label: I18n.tr("launchpadBlurWindow")
                    selected: ShellSettings.launchpadBackgroundMode
                        === "window"
                    onClicked:
                        ShellSettings.launchpadBackgroundMode = "window"
                }

                ModeButton {
                    label: I18n.tr("launchpadBlurWallpaper")
                    selected: ShellSettings.launchpadBackgroundMode
                        === "wallpaper"
                    onClicked:
                        ShellSettings.launchpadBackgroundMode = "wallpaper"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: themeOptions.implicitHeight + Appearance.px(20)
            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

            ColumnLayout {
                id: themeOptions
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.spacingMedium
                }
                spacing: Appearance.spacingSmall

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        PanelText {
                            text: I18n.tr("wallpaperAutoTheme")
                            color: Appearance.layer0Text
                        }

                        PanelText {
                            text: I18n.tr("wallpaperAutoThemeHint")
                            color: Appearance.subtext
                            font.pixelSize: Appearance.smallFontSize
                        }
                    }

                    SettingSwitch {
                        checked: ShellSettings.wallpaperAutoTheme
                        onToggled: checked => ShellSettings.wallpaperAutoTheme = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingSmall

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("colorMode")
                        color: Appearance.layer0Text
                    }

                    ActionButton {
                        icon: "󰖔"
                        label: I18n.tr("light")
                        selected: Theme.mode === "light"
                        onClicked: Theme.setMode("light")
                    }

                    ActionButton {
                        icon: "󰖙"
                        label: I18n.tr("dark")
                        selected: Theme.mode === "dark"
                        onClicked: Theme.setMode("dark")
                    }
                }

                PanelText {
                    text: I18n.tr("matugenScheme")
                    color: Appearance.layer0Text
                    font.weight: Font.DemiBold
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: Appearance.px(6)
                    rowSpacing: Appearance.px(6)

                    Repeater {
                        model: root.schemes

                        delegate: ActionButton {
                            required property var modelData
                            Layout.fillWidth: true
                            icon: "󰏘"
                            label: I18n.tr(modelData.key)
                            selected: Theme.scheme === modelData.value
                            onClicked: Theme.setScheme(modelData.value)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            PanelText {
                Layout.fillWidth: true
                text: I18n.tr("wallpapers") + "  " + WallpaperService.wallpapers.length
                color: Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            PanelText {
                text: WallpaperService.directory
                color: Appearance.subtext
                elide: Text.ElideMiddle
                font.pixelSize: Appearance.smallFontSize
            }
        }

        GridView {
            id: wallpaperGrid

            readonly property int columnCount:
                width >= Appearance.px(660) ? 3 : 2

            Layout.fillWidth: true
            Layout.minimumHeight: Appearance.px(500)
            Layout.preferredHeight: Math.min(
                Appearance.px(680),
                Math.max(
                    Appearance.px(500),
                    Math.ceil(WallpaperService.wallpapers.length
                        / Math.max(1, columnCount))
                        * cellHeight))
            clip: true
            cellWidth: Math.floor(width / columnCount)
            cellHeight: Math.max(
                Appearance.px(160),
                Math.round(cellWidth * 0.62))
            model: WallpaperService.wallpapers

            delegate: Item {
                required property var modelData
                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                Rectangle {
                    anchors {
                        fill: parent
                        margins: Appearance.spacingTiny
                    }
                    radius: Appearance.smallRadius
                    color: Appearance.layer1
                    border.width: modelData === WallpaperService.currentPath ? 3 : 1
                    border.color: modelData === WallpaperService.currentPath ? Appearance.primary : Appearance.outline
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: WallpaperService.previewUrl(modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: Math.ceil(width)
                        sourceSize.height: Math.ceil(height)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.apply(modelData)
                    }
                }
            }

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
            }
        }
            }
        }
    }
}
