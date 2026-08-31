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

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component ActionButton: Rectangle {
        id: button

        required property string icon
        required property string label
        property bool selected: false
        signal clicked

        implicitWidth: buttonRow.implicitWidth + Appearance.px(20)
        implicitHeight: Appearance.px(34)
        radius: Appearance.px(10)
        color: selected ? Appearance.primaryContainer : buttonArea.containsMouse ? Appearance.layer1Active : Appearance.layer1
        border.width: selected ? 1 : 0
        border.color: Appearance.primary

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: Appearance.px(6)

            Text {
                text: button.icon
                color: button.selected ? Appearance.primaryContainerText : Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(15)
                }
            }

            PanelText {
                text: button.label
                color: button.selected ? Appearance.primaryContainerText : Appearance.layer1Text
                font.pixelSize: Appearance.smallFontSize
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    component ModeButton: Rectangle {
        id: button

        required property string label
        property bool selected: false
        signal clicked

        implicitWidth: modeLabel.implicitWidth + Appearance.px(20)
        implicitHeight: Appearance.px(34)
        radius: Appearance.px(9)
        color: selected ? Appearance.primaryContainer : modeButtonArea.containsMouse ? Appearance.layer1Active : Appearance.layer1

        PanelText {
            id: modeLabel

            anchors.centerIn: parent
            text: button.label
            color: button.selected ? Appearance.primaryContainerText : Appearance.layer1Text
            font {
                pixelSize: Appearance.smallFontSize
                weight: button.selected ? Font.DemiBold : Font.Normal
            }
        }

        MouseArea {
            id: modeButtonArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }
    }

    component SettingSwitch: Item {
        id: control

        required property bool checked
        signal toggled(bool checked)

        implicitWidth: Appearance.px(43)
        implicitHeight: Appearance.px(25)

        Rectangle {
            anchors.fill: parent
            radius: Appearance.fullRadius
            color: control.checked ? Appearance.primary : Appearance.layer1Active
            border.width: control.checked ? 0 : 1
            border.color: Appearance.subtext

            Rectangle {
                width: control.checked ? Appearance.px(19) : Appearance.px(15)
                height: width
                radius: Appearance.fullRadius
                anchors.verticalCenter: parent.verticalCenter
                x: control.checked ? parent.width - width - Appearance.px(3) : Appearance.px(5)
                color: control.checked ? Theme.palette.m3onPrimary : Appearance.subtext

                Behavior on x {
                    NumberAnimation {
                        duration: Appearance.fastDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: control.toggled(!control.checked)
        }
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

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(18)
        }
        spacing: Appearance.px(10)

        SettingsPageHeader {
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
                    spacing: Appearance.px(8)

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
            spacing: Appearance.px(7)

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
            spacing: Appearance.px(6)

            PanelText {
                text: I18n.tr("wallpaperDisplayMode")
                color: Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.px(6)

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
            spacing: Appearance.px(6)

            PanelText {
                text: I18n.tr("wallpaperTransition")
                color: Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.px(6)

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
                    margins: Appearance.px(10)
                }
                spacing: Appearance.px(8)

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
                    margins: Appearance.px(10)
                }
                spacing: Appearance.px(8)

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
                    spacing: Appearance.px(7)

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

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 4
            cellHeight: Appearance.px(135)
            model: WallpaperService.wallpapers

            delegate: Item {
                required property var modelData
                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                Rectangle {
                    anchors {
                        fill: parent
                        margins: Appearance.px(4)
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
                        sourceSize.width: Appearance.px(240)
                        sourceSize.height: Appearance.px(140)
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
