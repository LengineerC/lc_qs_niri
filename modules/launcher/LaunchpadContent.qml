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
    readonly property int gridColumns: Math.max(1, Math.min(9,
        Math.floor(applicationGrid.width / Appearance.px(144))))

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
        origin.y: root.height * 0.35
        xScale: 0.97 + root.revealProgress * 0.03
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
        spacing: Appearance.spacingXLarge

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(Appearance.px(520),
                root.width - Appearance.px(72))
            Layout.maximumWidth: Math.min(Appearance.px(520),
                root.width - Appearance.px(72))
            spacing: Appearance.px(11)

            Item {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(48)

                LauncherSearchSurface {
                    id: searchField

                    readonly property bool expanded:
                        searchInput.text.length > 0

                    anchors.centerIn: parent
                    width: expanded
                        ? parent.width
                        : Math.min(parent.width, Appearance.px(250))
                    height: expanded
                        ? Appearance.px(48) : Appearance.px(40)
                    clip: true
                    highlighted: expanded && searchInput.activeFocus

                    Behavior on width {
                        NumberAnimation {
                            duration: Appearance.spatialDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Appearance.px(16)
                            rightMargin: Appearance.px(10)
                        }
                        spacing: Appearance.px(9)

                        AppText {
                            text: "󰍉"
                            color: searchInput.activeFocus
                                ? Appearance.barPrimary
                                : Appearance.barSubtext
                            font {
                                family: Appearance.iconFontFamily
                                weight: Font.Normal
                                pixelSize: Appearance.px(18)
                            }
                        }

                        AppTextField {
                            id: searchInput

                            Layout.fillWidth: true
                            padding: 0
                            placeholderText: I18n.tr("searchApplications")
                            color: Appearance.barLayer0Text
                            placeholderTextColor: Appearance.barSubtext
                            selectionColor: Appearance.barPrimaryContainer
                            selectedTextColor:
                                Appearance.barPrimaryContainerText
                            selectByMouse: true
                            cursorDelegate: Rectangle {
                                id: searchCursor

                                width: Appearance.px(1)
                                color: Appearance.barPrimary
                                visible: searchField.expanded
                                    && searchInput.activeFocus
                                opacity: 1

                                Timer {
                                    interval: 500
                                    running: searchCursor.visible
                                    repeat: true
                                    onTriggered: searchCursor.opacity =
                                        searchCursor.opacity > 0 ? 0 : 1
                                    onRunningChanged: {
                                        if (running)
                                            searchCursor.opacity = 1;
                                    }
                                }
                            }
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

                            AppText {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: Appearance.barLayer1Text
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
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
            }

            AppText {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.tr("launcherAppCount").arg(root.filteredApplications.length)
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
            Layout.maximumWidth: searchInput.text.trim().length > 0
                    && root.filteredApplications.length > 0
                ? Appearance.px(160) * Math.min(9, root.filteredApplications.length)
                : Appearance.px(1440)
            Layout.alignment: Qt.AlignHCenter

            GridView {
                id: applicationGrid

                anchors.fill: parent
                visible: count > 0
                clip: true
                model: root.filteredApplications
                currentIndex: count > 0 ? 0 : -1
                cellWidth: width / Math.max(1, root.gridColumns)
                cellHeight: Appearance.px(144)
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                flickDeceleration: 2400
                cacheBuffer: cellHeight
                reuseItems: true

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                delegate: Item {
                    id: applicationDelegate

                    required property var modelData
                    required property int index

                    width: applicationGrid.cellWidth
                    height: applicationGrid.cellHeight

                    MouseArea {
                        id: appArea

                        anchors {
                            fill: parent
                            margins: Appearance.spacingTiny
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
                        spacing: Appearance.spacingSmall

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Appearance.px(96)
                            height: width

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.px(24)
                                color: Appearance.withAlpha(
                                    Appearance.barLayer0Text,
                                    appArea.pressed ? 0.18
                                        : applicationDelegate.GridView.isCurrentItem
                                            ? 0.10 : 0)
                                border.width: 1
                                border.color: Appearance.withAlpha(
                                    Appearance.barLayer0Text,
                                    applicationDelegate.GridView.isCurrentItem ? 0.18 : 0)
                                Behavior on color {
                                    ColorAnimation { duration: Appearance.fastDuration }
                                }
                            }

                            LauncherIcon {
                                anchors.centerIn: parent
                                iconSize: Appearance.px(76)
                                iconName: applicationDelegate.modelData.icon
                                hovered: appArea.containsMouse
                                pressed: appArea.pressed
                            }
                        }

                        AppText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: applicationDelegate.modelData.name
                            color: Appearance.barLayer0Text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            style: ShellSettings.barFrostedGlass
                                || Theme.darkMode ? Text.Raised : Text.Normal
                            styleColor: "#80000000"
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

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰍉"
                    color: Appearance.barPrimary
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
                        pixelSize: Appearance.px(42)
                    }
                }

                AppText {
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
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacingLarge

            AppText {
                text: I18n.tr("launcherNavigateHint")
                color: Appearance.barSubtext
                font.pixelSize: Appearance.smallFontSize
            }
            AppText {
                text: I18n.tr("launcherOpenHint")
                color: Appearance.barSubtext
                font.pixelSize: Appearance.smallFontSize
            }
            AppText {
                text: I18n.tr("launcherCloseHint")
                color: Appearance.barSubtext
                font.pixelSize: Appearance.smallFontSize
            }
        }

    }
}
