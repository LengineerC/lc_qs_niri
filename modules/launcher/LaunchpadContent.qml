pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.common.widgets

Item {
    id: root

    property bool active: false
    property real revealProgress: 0
    signal closeRequested

    readonly property var applications: {
        const seen = new Set();
        return Array.from(DesktopEntries.applications.values)
            .filter(entry => {
                if (!entry || entry.noDisplay || !entry.name)
                    return false;
                if (seen.has(entry.id))
                    return false;
                seen.add(entry.id);
                return true;
            })
            .sort((first, second) =>
                first.name.localeCompare(second.name, I18n.language));
    }
    readonly property var filteredApplications: {
        const query = searchInput.text.trim().toLocaleLowerCase();
        if (!query)
            return applications;

        return applications.map(entry => ({
            entry: entry,
            score: searchScore(entry, query)
        })).filter(result => result.score >= 0)
            .sort((first, second) => {
                if (first.score !== second.score)
                    return first.score - second.score;
                return first.entry.name.localeCompare(
                    second.entry.name, I18n.language);
            })
            .map(result => result.entry);
    }
    readonly property int gridColumns: Math.max(3, Math.min(12,
        Math.floor(applicationGrid.width / Appearance.px(118))))

    function searchableText(entry) {
        return [
            entry.name,
            entry.genericName,
            entry.comment,
            entry.id,
            entry.startupClass,
            Array.from(entry.keywords || []).join(" ")
        ].filter(value => value).join(" ").toLocaleLowerCase();
    }

    function searchScore(entry, query) {
        const name = String(entry.name || "").toLocaleLowerCase();
        const genericName = String(
            entry.genericName || "").toLocaleLowerCase();
        const id = String(entry.id || "").toLocaleLowerCase();

        if (name === query)
            return 0;
        if (name.startsWith(query))
            return 10;
        if (genericName.startsWith(query))
            return 20;
        if (id.startsWith(query))
            return 30;

        const nameIndex = name.indexOf(query);
        if (nameIndex >= 0)
            return 40 + nameIndex;

        const searchIndex = searchableText(entry).indexOf(query);
        return searchIndex >= 0 ? 100 + searchIndex : -1;
    }

    function launch(entry) {
        if (!entry)
            return;
        closeRequested();
        entry.execute();
    }

    function launchCurrent() {
        if (applicationGrid.count === 0)
            return;
        const index = Math.max(0, applicationGrid.currentIndex);
        launch(filteredApplications[index]);
    }

    function moveSelection(offset) {
        if (applicationGrid.count === 0)
            return;
        const current = Math.max(0, applicationGrid.currentIndex);
        applicationGrid.currentIndex = Math.max(0,
            Math.min(applicationGrid.count - 1, current + offset));
        applicationGrid.positionViewAtIndex(
            applicationGrid.currentIndex, GridView.Contain);
    }

    function focusSearch() {
        searchInput.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    onActiveChanged: {
        if (!active)
            return;
        applicationGrid.currentIndex =
            filteredApplications.length > 0 ? 0 : -1;
        Qt.callLater(focusSearch);
    }

    onFilteredApplicationsChanged: {
        applicationGrid.currentIndex =
            filteredApplications.length > 0 ? 0 : -1;
        applicationGrid.positionViewAtBeginning();
    }

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: 0.94 + root.revealProgress * 0.06
        yScale: xScale
    }
    opacity: revealProgress

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: Math.max(Appearance.px(42), parent.height * 0.065)
            bottomMargin: Math.max(Appearance.px(28), parent.height * 0.035)
            leftMargin: Math.max(Appearance.px(28), parent.width * 0.035)
            rightMargin: Math.max(Appearance.px(28), parent.width * 0.035)
        }
        spacing: Appearance.px(20)

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(Appearance.px(520),
                root.width - Appearance.px(72))
            Layout.maximumWidth: Math.min(Appearance.px(520),
                root.width - Appearance.px(72))
            spacing: Appearance.px(11)

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.tr("launcher")
                color: Appearance.barLayer0Text
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(24)
                    weight: Font.DemiBold
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(48)
                radius: Appearance.smallRadius
                // Match the search field in the launcher panel opened by a
                // left click on the Bar's system icon.
                color: Appearance.barLayer1
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: Appearance.barPrimary

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.px(16)
                        rightMargin: Appearance.px(10)
                    }
                    spacing: Appearance.px(9)

                    Text {
                        text: "󰍉"
                        color: searchInput.activeFocus
                            ? Appearance.barPrimary : Appearance.barSubtext
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(18)
                        }
                    }

                    Controls.TextField {
                        id: searchInput

                        Layout.fillWidth: true
                        padding: 0
                        placeholderText: I18n.tr("searchApplications")
                        color: Appearance.barLayer0Text
                        placeholderTextColor: Appearance.barSubtext
                        selectionColor: Appearance.barPrimaryContainer
                        selectedTextColor: Appearance.barPrimaryContainerText
                        selectByMouse: true
                        background: null
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.fontSize
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Right) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.moveSelection(root.gridColumns);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-root.gridColumns);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageDown) {
                                root.moveSelection(root.gridColumns * 3);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                root.moveSelection(-root.gridColumns * 3);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter) {
                                root.launchCurrent();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.closeRequested();
                                event.accepted = true;
                            }
                        }
                    }

                    Rectangle {
                        visible: searchInput.text.length > 0
                        implicitWidth: Appearance.px(28)
                        implicitHeight: Appearance.px(28)
                        radius: Appearance.fullRadius
                        color: clearArea.containsMouse
                            ? Appearance.barLayer1Active : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: Appearance.barLayer1Text
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(13)
                            }
                        }

                        MouseArea {
                            id: clearArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.clear()
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.filteredApplications.length
                    + " / " + root.applications.length
                color: Appearance.withAlpha(Appearance.barLayer0Text, 0.66)
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.smallFontSize
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: Appearance.px(1500)
            Layout.alignment: Qt.AlignHCenter

            GridView {
                id: applicationGrid

                anchors.fill: parent
                visible: count > 0
                clip: true
                model: root.filteredApplications
                currentIndex: count > 0 ? 0 : -1
                cellWidth: width / Math.max(1, root.gridColumns)
                cellHeight: Appearance.px(116)
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                flickDeceleration: 2400

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                delegate: Item {
                    id: applicationDelegate

                    required property var modelData
                    required property int index

                    width: applicationGrid.cellWidth
                    height: applicationGrid.cellHeight

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: Appearance.px(4)
                        }
                        radius: Appearance.normalRadius
                        color: applicationDelegate.GridView.isCurrentItem
                                || appArea.containsMouse
                            ? (ShellSettings.barFrostedGlass
                                ? Appearance.barLayer2
                                : Appearance.withAlpha(
                                    Appearance.barLayer2, 0.62))
                            : Appearance.withAlpha(Appearance.barLayer2, 0)
                        border.width:
                            applicationDelegate.GridView.isCurrentItem ? 1 : 0
                        border.color: Appearance.withAlpha(
                            Appearance.barPrimary, 0.82)

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.fastDuration
                            }
                        }
                    }

                    MouseArea {
                        id: appArea

                        anchors {
                            fill: parent
                            margins: Appearance.px(4)
                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered:
                            applicationGrid.currentIndex =
                                applicationDelegate.index
                        onClicked: root.launch(
                            applicationDelegate.modelData)
                    }

                    Column {
                        anchors.centerIn: parent
                        width: Math.max(0,
                            applicationDelegate.width - Appearance.px(14))
                        spacing: Appearance.px(8)

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Appearance.px(70)
                            height: width
                            radius: Appearance.px(18)
                            color: ShellSettings.barFrostedGlass
                                ? Appearance.barPrimaryContainer
                                : Appearance.withAlpha(
                                    Appearance.barPrimaryContainer, 0.72)
                            border.width: 1
                            border.color: Appearance.withAlpha(
                                Appearance.barLayer0Text, 0.1)

                            IconImage {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(9)
                                }
                                asynchronous: true
                                source: Quickshell.iconPath(
                                    applicationDelegate.modelData.icon,
                                    "application-x-executable")
                                layer.enabled:
                                    ShellSettings.monochromeAppIconsActive
                                layer.effect: MultiEffect {
                                    saturation: -1
                                    brightness: 0.12
                                    contrast: 0.08
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: applicationDelegate.modelData.name
                            color: Appearance.barLayer0Text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font {
                                family: Appearance.fontFamily
                                pixelSize: Appearance.fontSize
                                weight: Font.Medium
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: applicationGrid.count === 0
                spacing: Appearance.px(10)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰍉"
                    color: Appearance.barPrimary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(42)
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("noApplicationsFound")
                    color: Appearance.barLayer0Text
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.largeFontSize
                    }
                }
            }
        }
    }
}
