pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common

Rectangle {
    id: root

    required property QsMenuEntry menuEntry
    property bool forceIconColumn: false
    property bool forceControlColumn: false

    signal dismiss
    signal openSubmenu(QsMenuHandle handle, string title)

    readonly property bool separator: menuEntry.isSeparator
    readonly property bool hasIcon: String(menuEntry.icon ?? "").length > 0
    readonly property bool hasControl:
        menuEntry.buttonType !== QsMenuButtonType.None
    readonly property bool checked:
        menuEntry.checkState === Qt.Checked
    readonly property bool partiallyChecked:
        menuEntry.checkState === Qt.PartiallyChecked
    readonly property color foreground: entryMouse.containsMouse
        ? Appearance.primaryContainerText : Appearance.layer0Text

    Layout.fillWidth: true
    Layout.topMargin: separator ? Appearance.px(4) : 0
    Layout.bottomMargin: separator ? Appearance.px(4) : 0
    implicitHeight: separator ? Appearance.px(1) : Appearance.px(40)
    radius: Appearance.px(10)
    color: separator ? Appearance.outline
        : entryMouse.containsMouse && root.enabled
            ? Appearance.primaryContainer
            : Appearance.withAlpha(Appearance.primaryContainer, 0)
    opacity: separator || root.enabled ? 1 : 0.42
    enabled: !separator && menuEntry.enabled
    scale: entryMouse.pressed ? 0.98 : 1

    RowLayout {
        id: contentRow

        visible: !root.separator
        anchors {
            fill: parent
            leftMargin: Appearance.px(11)
            rightMargin: Appearance.px(9)
        }
        spacing: Appearance.px(8)

        Item {
            visible: root.forceControlColumn || root.hasControl
            Layout.preferredWidth: Appearance.px(20)
            Layout.preferredHeight: Appearance.px(20)
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                visible: root.menuEntry.buttonType
                    === QsMenuButtonType.RadioButton
                anchors.centerIn: parent
                width: Appearance.px(17)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Appearance.px(2)
                border.color: root.checked
                    ? Appearance.primary : root.foreground

                Rectangle {
                    anchors.centerIn: parent
                    width: root.checked
                        ? Appearance.px(8) : 0
                    height: width
                    radius: width / 2
                    color: Appearance.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Rectangle {
                visible: root.menuEntry.buttonType
                    === QsMenuButtonType.CheckBox
                anchors.centerIn: parent
                width: Appearance.px(17)
                height: width
                radius: Appearance.px(5)
                color: root.checked || root.partiallyChecked
                    ? Appearance.primary : "transparent"
                border.width: root.checked || root.partiallyChecked
                    ? 0 : Appearance.px(2)
                border.color: root.foreground

                Text {
                    anchors.centerIn: parent
                    text: root.partiallyChecked ? "−" : "✓"
                    visible: root.checked || root.partiallyChecked
                    color: Appearance.primaryContainer
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.px(12)
                        weight: Font.Bold
                    }
                }
            }
        }

        Item {
            visible: root.forceIconColumn || root.hasIcon
            Layout.preferredWidth: Appearance.px(21)
            Layout.preferredHeight: Appearance.px(21)
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                visible: root.hasIcon
                anchors.centerIn: parent
                source: root.menuEntry.icon
                implicitSize: Appearance.px(20)
                asynchronous: true
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.menuEntry.text
            color: root.foreground
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font {
                family: Appearance.fontFamily
                pixelSize: Appearance.fontSize
            }
        }

        Text {
            visible: root.menuEntry.hasChildren
            text: "󰅂"
            color: root.foreground
            font {
                family: Appearance.iconFontFamily
                pixelSize: Appearance.px(15)
            }
        }
    }

    MouseArea {
        id: entryMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled
            ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton

        onClicked: {
            if (root.menuEntry.hasChildren) {
                root.openSubmenu(
                    root.menuEntry, root.menuEntry.text);
                return;
            }

            root.menuEntry.triggered();
            root.dismiss();
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.fastDuration
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.fastDuration
            easing.type: Easing.OutCubic
        }
    }
}
