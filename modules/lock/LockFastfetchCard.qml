pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: root

    // LockContent 可以独立调整这些参数，不影响侧边栏卡片。
    property real fontScale: 1.0
    property real contentPadding: Appearance.px(10)
    property real sectionSpacing: Appearance.px(5)
    property real rowSpacing: Appearance.px(2)
    // 同时缩放 Logo、背景容器和左侧布局占位。
    property real iconScale: 1.0

    readonly property real adaptiveScale: Math.max(0.82,
        Math.min(1, height / Appearance.px(225)))
    readonly property real bodyHeight: Math.max(Appearance.px(56),
        height - contentPadding * 2 - Appearance.px(30)
            - sectionSpacing)
    readonly property real logoExtent: Math.max(Appearance.px(56),
        Math.min(
            Appearance.px(92) * Math.max(0.5, iconScale),
            width * 0.46,
            bodyHeight * 0.92
        ))
    readonly property string unknownValue: "—"
    readonly property var informationRows: [
        {
            icon: "󰍹",
            label: "OS",
            value: FastfetchService.osName || unknownValue
        },
        {
            icon: "󰕮",
            label: "WM",
            value: FastfetchService.windowManager || unknownValue
        },
        {
            icon: "󰀄",
            label: "USER",
            value: FastfetchService.userName
                || UserService.loginName || unknownValue
        },
        {
            icon: "󰔟",
            label: "UP",
            value: UserService.formatUptime()
        },
        {
            icon: "󰒋",
            label: "KERN",
            value: FastfetchService.kernel || unknownValue
        },
        {
            icon: "󰆍",
            label: "SH",
            value: FastfetchService.shellName || unknownValue
        }
    ]
    readonly property var paletteColors:
        ShellSettings.barFrostedGlass ? [
            "#f0ffffff", "#c9ffffff", "#a3ffffff",
            "#7dffffff", "#57ffffff", "#31ffffff"
        ] : [
            Appearance.barPrimary,
            Theme.palette.m3secondary,
            Theme.palette.m3tertiary,
            Theme.palette.m3success,
            Theme.palette.m3surfaceVariant,
            Theme.palette.m3primaryContainer
        ]

    function fontSize(baseSize) {
        return Math.max(Appearance.px(8), Math.round(
            Appearance.px(baseSize) * fontScale * adaptiveScale));
    }

    function iconSize(baseSize) {
        return Math.max(Appearance.px(24), Math.round(
            Appearance.px(baseSize) * iconScale * adaptiveScale
        ));
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Appearance.normalRadius
    color: Appearance.barLayer2
    border.width: 1
    border.color: Appearance.barOutline
    clip: true

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.contentPadding
        }
        spacing: root.sectionSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.px(30)
            spacing: Appearance.px(8)

            Rectangle {
                Layout.preferredWidth: Appearance.px(30)
                Layout.preferredHeight: width
                radius: Appearance.px(9)
                color: Appearance.barPrimaryContainer

                AppText {
                    anchors.centerIn: parent
                    text: ">"
                    color: Appearance.barPrimaryContainerText
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: root.fontSize(14)
                        weight: Font.Bold
                    }
                }
            }

            AppText {
                Layout.fillWidth: true
                text: "fastfetch"
                color: Appearance.barLayer0Text
                elide: Text.ElideRight
                font {
                    family: Appearance.monospaceFontFamily
                    pixelSize: root.fontSize(14)
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                Layout.preferredWidth: Appearance.px(7)
                Layout.preferredHeight: width
                radius: Appearance.fullRadius
                color: FastfetchService.errorMessage
                    ? Appearance.barError
                    : FastfetchService.loading
                        ? Appearance.barTertiary : Appearance.barPrimary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.px(15)

            Item {
                // 占位宽度与 Logo 一起缩放，右侧内容因此同步移动。
                Layout.preferredWidth: root.logoExtent
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: root.logoExtent
                    height: width
                    radius: width * 0.3
                    color: Appearance.barLayer3
                    border.width: 1
                    border.color: Appearance.withAlpha(
                        Appearance.barPrimary, 0.14)

                    AppText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Appearance.px(1)
                        text: FastfetchService.systemIcon
                        color: Appearance.barPrimary
                        font {
                            family: Appearance.iconFontFamily
                            weight: Font.Normal
                            pixelSize: Math.min(
                                parent.width * 0.68,
                                root.iconSize(58))
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: root.rowSpacing + 5

                AppText {
                    Layout.fillWidth: true
                    text: FastfetchService.title
                    color: Appearance.barPrimary
                    elide: Text.ElideRight
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: root.fontSize(12)
                        weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Appearance.barOutline
                }

                Repeater {
                    model: root.informationRows

                    delegate: RowLayout {
                        id: informationRow

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(
                            Appearance.px(16), root.fontSize(11) + 2)
                        spacing: Appearance.px(4)

                        AppText {
                            Layout.preferredWidth: Appearance.px(16)
                            text: informationRow.modelData.icon
                            color: Appearance.barPrimary
                            horizontalAlignment: Text.AlignHCenter
                            font {
                                family: Appearance.iconFontFamily
                                weight: Font.Normal
                                pixelSize: root.fontSize(13)
                            }
                        }

                        AppText {
                            Layout.preferredWidth: Appearance.px(40)
                            text: informationRow.modelData.label + ":"
                            color: Appearance.barLayer1Text
                            font {
                                family: Appearance.monospaceFontFamily
                                pixelSize: root.fontSize(10)
                                weight: Font.DemiBold
                            }
                        }

                        AppText {
                            Layout.fillWidth: true
                            text: informationRow.modelData.value
                            color: Appearance.barLayer0Text
                            elide: Text.ElideRight
                            font {
                                family: Appearance.monospaceFontFamily
                                pixelSize: root.fontSize(10)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(1)
                    spacing: Appearance.px(4)

                    Repeater {
                        model: root.paletteColors

                        delegate: Rectangle {
                            required property color modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: Appearance.px(9)
                            radius: Appearance.px(4)
                            color: modelData
                        }
                    }
                }
            }
        }
    }
}
