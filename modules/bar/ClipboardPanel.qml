pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    readonly property var filteredEntries: {
        const entries = ClipboardService.entries;
        const query = searchInput.text.trim().toLocaleLowerCase();
        if (!query)
            return entries;
        return entries.filter(entry => {
            const searchable = entry.kind === "text"
                ? entry.preview : entry.mime;
            return String(searchable).toLocaleLowerCase().includes(query);
        });
    }
    property string selectedEntryId: ""

    implicitWidth: Appearance.px(520)
    implicitHeight: Appearance.px(560)

    function formatSize(bytes) {
        if (bytes >= 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MB";
        if (bytes >= 1024)
            return (bytes / 1024).toFixed(1) + " KB";
        return bytes + " B";
    }

    function copyAndClose(entryId) {
        ClipboardService.copyEntry(entryId);
        closeRequested();
    }

    function setSelectedIndex(index, position = true) {
        const count = filteredEntries.length;
        if (count === 0) {
            historyList.currentIndex = -1;
            selectedEntryId = "";
            return;
        }

        const nextIndex = Math.max(0, Math.min(count - 1, index));
        historyList.currentIndex = nextIndex;
        selectedEntryId = String(filteredEntries[nextIndex].id);

        if (position) {
            Qt.callLater(() => historyList.positionViewAtIndex(
                nextIndex, ListView.Contain));
        }
    }

    function reconcileSelection() {
        if (!visible || filteredEntries.length === 0) {
            historyList.currentIndex = -1;
            selectedEntryId = "";
            return;
        }

        if (selectedEntryId) {
            const selectedIndex = filteredEntries.findIndex(
                entry => String(entry.id) === selectedEntryId);
            if (selectedIndex >= 0) {
                setSelectedIndex(selectedIndex);
                return;
            }
        }

        setSelectedIndex(0);
    }

    function moveSelection(offset) {
        if (filteredEntries.length === 0)
            return;

        if (historyList.currentIndex < 0) {
            setSelectedIndex(offset < 0
                ? filteredEntries.length - 1 : 0);
            return;
        }

        setSelectedIndex(historyList.currentIndex + offset);
    }

    function activateSelection() {
        const index = historyList.currentIndex;
        if (index < 0 || index >= filteredEntries.length)
            return;
        copyAndClose(filteredEntries[index].id);
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    onVisibleChanged: {
        if (visible) {
            ClipboardService.refresh();
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
                root.reconcileSelection();
            });
        } else {
            searchInput.text = "";
            selectedEntryId = "";
            historyList.currentIndex = -1;
        }
    }

    onFilteredEntriesChanged: Qt.callLater(root.reconcileSelection)

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(10)

        PopupHeader {
            icon: "󰅇"
            title: I18n.tr("clipboard")
            subtitle: I18n.tr("clipboardHistoryHint")

            Rectangle {
                implicitWidth: clearLabel.implicitWidth + Appearance.px(18)
                implicitHeight: Appearance.px(28)
                radius: Appearance.fullRadius
                color: clearMouse.containsMouse
                    ? Theme.palette.m3errorContainer
                    : Appearance.withAlpha(
                        Theme.palette.m3errorContainer, 0)


                PanelText {
                    id: clearLabel

                    anchors.centerIn: parent
                    text: "󰃢  " + I18n.tr("clear")
                    color: clearMouse.containsMouse
                        ? Theme.palette.m3onErrorContainer : Appearance.subtext
                    font.pixelSize: Appearance.smallFontSize
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    enabled: ClipboardService.entries.length > 0
                    hoverEnabled: true
                    cursorShape: enabled
                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: ClipboardService.clearHistory()
                }

                Behavior on color {
                    ColorAnimation { duration: Appearance.fastDuration }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(38)
            radius: Appearance.px(11)
            color: Appearance.layer1
            border.width: searchInput.activeFocus ? 1 : 0
            border.color: Appearance.primary

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(11)
                    rightMargin: Appearance.px(7)
                }
                spacing: Appearance.px(7)

                Text {
                    text: "󰍉"
                    color: searchInput.activeFocus
                        ? Appearance.primary : Appearance.subtext
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(16)
                    }
                }

                Controls.TextField {
                    id: searchInput

                    Layout.fillWidth: true
                    padding: 0
                    placeholderText: I18n.tr("searchClipboard")
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

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return
                                || event.key === Qt.Key_Enter) {
                            root.activateSelection();
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    visible: searchInput.text.length > 0
                    implicitWidth: Appearance.px(24)
                    implicitHeight: Appearance.px(24)
                    radius: Appearance.fullRadius
                    color: searchClearMouse.containsMouse
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
                        id: searchClearMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.clear()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: historyList

                anchors.fill: parent
                clip: true
                spacing: Appearance.px(8)
                model: root.filteredEntries
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: Controls.ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: historyEntry

                    required property var modelData
                    required property int index

                    readonly property bool selected:
                        historyEntry.index === historyList.currentIndex

                    width: ListView.view.width
                    height: modelData.kind === "image"
                        ? Appearance.px(182) : Appearance.px(104)
                    radius: Appearance.smallRadius
                    color: historyEntry.selected
                        ? Appearance.primaryContainer
                        : entryMouse.containsMouse
                            ? Appearance.layer1Hover : Appearance.layer1
                    border.width: historyEntry.selected ? 2 : 1
                    border.color: historyEntry.selected
                        ? Appearance.primary : Appearance.outline
                    clip: true

                    MouseArea {
                        id: entryMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copyAndClose(historyEntry.modelData.id)
                    }

                    Image {
                        visible: historyEntry.modelData.kind === "image"
                        anchors {
                            fill: parent
                            margins: Appearance.px(8)
                        }
                        source: visible
                            ? "file://" + historyEntry.modelData.path : ""
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectFit
                        sourceSize {
                            width: Appearance.px(460)
                            height: Appearance.px(150)
                        }
                    }

                    ColumnLayout {
                        visible: historyEntry.modelData.kind === "text"
                        anchors {
                            fill: parent
                            margins: Appearance.px(11)
                            rightMargin: Appearance.px(42)
                        }
                        spacing: Appearance.px(4)

                        PanelText {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: historyEntry.modelData.preview
                            color: historyEntry.selected
                                ? Appearance.primaryContainerText
                                : Appearance.layer0Text
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                            maximumLineCount: 4
                            font.pixelSize: Appearance.smallFontSize
                        }

                        PanelText {
                            text: root.formatSize(
                                historyEntry.modelData.size)
                            color: historyEntry.selected
                                ? Appearance.primaryContainerText
                                : Appearance.subtext
                            font.pixelSize: Appearance.smallFontSize
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: Appearance.px(8)
                        }
                        implicitWidth: Appearance.px(28)
                        implicitHeight: Appearance.px(28)
                        radius: Appearance.fullRadius
                        color: deleteMouse.containsMouse
                            ? Theme.palette.m3errorContainer
                            : Appearance.layer2

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            color: deleteMouse.containsMouse
                                ? Theme.palette.m3onErrorContainer
                                : Appearance.subtext
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(14)
                            }
                        }

                        MouseArea {
                            id: deleteMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.deleteEntry(
                                historyEntry.modelData.id)
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: Appearance.fastDuration }
                    }
                }
            }

            Column {
                visible: !ClipboardService.refreshing
                    && root.filteredEntries.length === 0
                anchors.centerIn: parent
                spacing: Appearance.px(8)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text
                        ? "󰍉" : "󰅇"
                    color: Appearance.subtext
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(36)
                    }
                }

                PanelText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text
                        ? I18n.tr("noSearchResults")
                        : I18n.tr("clipboardEmpty")
                    color: Appearance.subtext
                }
            }

            Controls.BusyIndicator {
                visible: ClipboardService.refreshing
                    && ClipboardService.entries.length === 0
                running: visible
                anchors.centerIn: parent
            }
        }
    }
}
