pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.common.widgets

Item {
    id: root

    property bool active: false
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

    implicitWidth: Appearance.px(500)
    implicitHeight: Appearance.px(560)

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
        if (applicationList.count === 0)
            return;
        const index = Math.max(0, applicationList.currentIndex);
        launch(filteredApplications[index]);
    }

    function moveSelection(offset) {
        if (applicationList.count === 0)
            return;
        const current = Math.max(0, applicationList.currentIndex);
        applicationList.currentIndex = Math.max(0,
            Math.min(applicationList.count - 1, current + offset));
        applicationList.positionViewAtIndex(
            applicationList.currentIndex, ListView.Contain);
    }

    onActiveChanged: {
        if (active) {
            applicationList.currentIndex =
                filteredApplications.length > 0 ? 0 : -1;
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            searchInput.clear();
            applicationList.currentIndex = -1;
        }
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(10)

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(42)
            radius: Appearance.px(12)
            color: Appearance.layer1
            border.width: searchInput.activeFocus ? 1 : 0
            border.color: Appearance.primary

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(12)
                    rightMargin: Appearance.px(8)
                }
                spacing: Appearance.px(8)

                Text {
                    text: "󰍉"
                    color: searchInput.activeFocus
                        ? Appearance.primary : Appearance.subtext
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(17)
                    }
                }

                Controls.TextField {
                    id: searchInput

                    Layout.fillWidth: true
                    padding: 0
                    placeholderText: I18n.tr("searchApplications")
                    color: Appearance.layer0Text
                    placeholderTextColor: Appearance.subtext
                    selectionColor: Appearance.primaryContainer
                    selectedTextColor: Appearance.primaryContainerText
                    selectByMouse: true
                    background: null
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.fontSize
                    }

                    onTextChanged: {
                        applicationList.currentIndex =
                            root.filteredApplications.length > 0 ? 0 : -1;
                        applicationList.positionViewAtBeginning();
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
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
                    implicitWidth: Appearance.px(25)
                    implicitHeight: Appearance.px(25)
                    radius: Appearance.fullRadius
                    color: clearArea.containsMouse
                        ? Appearance.layer1Active : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Appearance.subtext
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

                CloseButton {
                    onClicked: root.closeRequested()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.px(3)
            Layout.rightMargin: Appearance.px(3)

            PanelText {
                Layout.fillWidth: true
                text: I18n.tr("applications")
                color: Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            PanelText {
                text: root.filteredApplications.length
                    + " / " + root.applications.length
                color: Appearance.subtext
                font.pixelSize: Appearance.smallFontSize
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: applicationList

                anchors.fill: parent
                visible: count > 0
                clip: true
                spacing: Appearance.px(5)
                model: root.filteredApplications
                currentIndex: count > 0 ? 0 : -1
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: applicationEntry

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                        - Appearance.px(8)
                    height: Appearance.px(58)
                    radius: Appearance.px(12)
                    color: applicationEntry.ListView.isCurrentItem
                            || entryArea.containsMouse
                        ? Appearance.layer1Hover : "transparent"
                    border.width:
                        applicationEntry.ListView.isCurrentItem ? 1 : 0
                    border.color: Appearance.primary

                    MouseArea {
                        id: entryArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered:
                            applicationList.currentIndex =
                                applicationEntry.index
                        onClicked:
                            root.launch(applicationEntry.modelData)
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Appearance.px(9)
                            rightMargin: Appearance.px(10)
                        }
                        spacing: Appearance.px(11)

                        Rectangle {
                            implicitWidth: Appearance.px(40)
                            implicitHeight: Appearance.px(40)
                            radius: Appearance.px(11)
                            color: Appearance.primaryContainer

                            IconImage {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(6)
                                }
                                asynchronous: true
                                source: Quickshell.iconPath(
                                    applicationEntry.modelData.icon,
                                    "application-x-executable")
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 0

                            PanelText {
                                Layout.fillWidth: true
                                text: applicationEntry.modelData.name
                                color: Appearance.layer0Text
                                elide: Text.ElideRight
                                font.weight: Font.DemiBold
                            }

                            PanelText {
                                Layout.fillWidth: true
                                text: applicationEntry.modelData.comment
                                    || applicationEntry.modelData.genericName
                                    || applicationEntry.modelData.id
                                color: Appearance.subtext
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.smallFontSize
                            }
                        }

                        Text {
                            text: "󰁔"
                            color: applicationEntry.ListView.isCurrentItem
                                ? Appearance.primary : Appearance.subtext
                            opacity: applicationEntry.ListView.isCurrentItem
                                || entryArea.containsMouse ? 1 : 0
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(16)
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.fastDuration
                                }
                            }
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.fastDuration
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: applicationList.count === 0
                spacing: Appearance.px(8)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰍉"
                    color: Appearance.primary
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(34)
                    }
                }

                PanelText {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.tr("noApplicationsFound")
                    color: Appearance.subtext
                }
            }
        }
    }
}
