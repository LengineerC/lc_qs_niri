pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: root

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }

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
    readonly property var paletteColors: [
        Appearance.primary,
        Theme.palette.m3secondary,
        Theme.palette.m3tertiary,
        Theme.palette.m3success,
        Theme.palette.m3surfaceVariant,
        Theme.palette.m3primaryContainer
    ]

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Appearance.px(28)
    radius: Appearance.px(24)
    color: Appearance.layer3
    border.width: 1
    border.color: Appearance.withAlpha(Appearance.outline, 0.58)
    clip: true

    ColumnLayout {
        id: content

        anchors {
            fill: parent
            margins: Appearance.px(10)
        }
        spacing: -Appearance.px(1)

        // RowLayout {
        //     Layout.fillWidth: true
        //     spacing: Appearance.px(10)

        //     Rectangle {
        //         Layout.preferredWidth: Appearance.px(34)
        //         Layout.preferredHeight: Appearance.px(34)
        //         radius: Appearance.px(11)
        //         color: Appearance.primaryContainer

        //         Text {
        //             anchors.centerIn: parent
        //             text: ">"
        //             color: Appearance.primaryContainerText
        //             font {
        //                 family: Appearance.monospaceFontFamily
        //                 pixelSize: Appearance.px(16)
        //                 weight: Font.Bold
        //             }
        //         }
        //     }

        //     Text {
        //         Layout.fillWidth: true
        //         text: "fastfetch"
        //         color: Appearance.layer0Text
        //         font {
        //             family: Appearance.monospaceFontFamily
        //             pixelSize: Appearance.px(15)
        //             weight: Font.DemiBold
        //         }
        //     }

        //     Rectangle {
        //         Layout.preferredWidth: Appearance.px(7)
        //         Layout.preferredHeight: Appearance.px(7)
        //         radius: Appearance.fullRadius
        //         color: FastfetchService.errorMessage
        //             ? Theme.palette.m3error
        //             : FastfetchService.loading
        //                 ? Appearance.tertiary : Appearance.primary

        //         SequentialAnimation on opacity {
        //             running: FastfetchService.loading
        //             loops: Animation.Infinite
        //             NumberAnimation {
        //                 to: 0.3
        //                 duration: 550
        //             }
        //             NumberAnimation {
        //                 to: 1
        //                 duration: 550
        //             }
        //         }
        //     }
        // }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.px(170)
            spacing: Appearance.px(16)

            Item {
                Layout.preferredWidth: Appearance.px(112)
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: Appearance.px(108)
                    height: width
                    radius: Appearance.px(34)
                    color: Appearance.withAlpha(
                        Appearance.primary, 0.075)
                    border.width: 1
                    border.color: Appearance.withAlpha(
                        Appearance.primary, 0.12)

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Appearance.px(2)
                        text: FastfetchService.systemIcon
                        color: Appearance.primary
                        font {
                            family: "Symbols Nerd Font"
                            pixelSize: Appearance.px(72)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Appearance.px(4)

                Text {
                    Layout.fillWidth: true
                    text: FastfetchService.title
                    color: Appearance.primary
                    elide: Text.ElideRight
                    font {
                        family: Appearance.monospaceFontFamily
                        pixelSize: Appearance.px(15)
                        weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Appearance.withAlpha(
                        Appearance.outline, 0.75)
                }

                Repeater {
                    model: root.informationRows

                    delegate: RowLayout {
                        id: informationRow

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: Appearance.px(21)
                        spacing: Appearance.px(5)

                        Text {
                            Layout.preferredWidth: Appearance.px(18)
                            horizontalAlignment: Text.AlignHCenter
                            text: informationRow.modelData.icon
                            color: Appearance.primary
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(15)
                            }
                        }

                        Text {
                            Layout.preferredWidth: Appearance.px(42)
                            text: informationRow.modelData.label + ":"
                            color: Appearance.layer1Text
                            font {
                                family: Appearance.monospaceFontFamily
                                pixelSize: Appearance.px(13)
                                weight: Font.DemiBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: informationRow.modelData.value
                            color: Appearance.layer0Text
                            elide: Text.ElideRight
                            font {
                                family: Appearance.monospaceFontFamily
                                pixelSize: Appearance.px(12)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.px(2)
                    spacing: Appearance.px(5)

                    Repeater {
                        model: root.paletteColors

                        delegate: Rectangle {
                            required property color modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: Appearance.px(13)
                            radius: Appearance.px(5)
                            color: modelData
                            border.width: 1
                            border.color: Appearance.withAlpha(
                                Appearance.layer0Text, 0.08)
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: FastfetchService.errorMessage.length > 0
            text: FastfetchService.errorMessage
            color: Theme.palette.m3error
            elide: Text.ElideRight
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.smallFontSize
            }
        }
    }
}
