pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    property bool active: false
    property bool useBarPalette: true
    property string processScope: "all"
    property string sortKey: "cpu"
    property bool sortDescending: true
    property int expandedPid: -1
    property var contextEntry: null
    property var confirmEntry: null
    property real contextX: 0
    property real contextY: 0
    property bool viewerRegistered: false

    signal closeRequested

    BarPalette {
        id: panelPalette
        enabled: root.useBarPalette
    }

    readonly property var filteredProcesses: {
        const query = searchInput.text.trim().toLocaleLowerCase();
        const entries = ResourceService.processes.filter(entry => {
            if (processScope === "user"
                    && entry.uid !== ResourceService.currentUid)
                return false;
            if (!query)
                return true;
            return String(entry.name).toLocaleLowerCase().includes(query)
                || String(entry.command)
                    .toLocaleLowerCase().includes(query)
                || String(entry.pid).includes(query);
        });
        return entries.sort((first, second) => {
            const firstValue = sortKey === "memory"
                ? first.pssKb : first.cpu;
            const secondValue = sortKey === "memory"
                ? second.pssKb : second.cpu;
            const difference = firstValue - secondValue;
            if (difference !== 0)
                return sortDescending ? -difference : difference;
            return String(first.name).localeCompare(String(second.name));
        });
    }

    implicitWidth: Appearance.px(820)
    implicitHeight: Appearance.px(700)

    function setViewerActive(enabled) {
        if (enabled === viewerRegistered)
            return;
        viewerRegistered = enabled;
        if (enabled)
            ResourceService.startProcessViewer();
        else
            ResourceService.stopProcessViewer();
    }

    function setSort(key) {
        resetProcessScroll();
        if (sortKey === key)
            sortDescending = !sortDescending;
        else {
            sortKey = key;
            sortDescending = true;
        }
    }

    function sortArrow(key) {
        if (sortKey !== key)
            return "";
        return sortDescending ? "  ↓" : "  ↑";
    }

    function openContextMenu(entry, item, localX, localY) {
        const point = item.mapToItem(root, localX, localY);
        const menuWidth = Appearance.px(230);
        const menuHeight = Appearance.px(220);
        contextX = Math.max(Appearance.px(8),
            Math.min(root.width - menuWidth - Appearance.px(8), point.x));
        contextY = Math.max(Appearance.px(8),
            Math.min(root.height - menuHeight - Appearance.px(8), point.y));
        contextEntry = entry;
    }

    function closeTransientUi() {
        contextEntry = null;
        confirmEntry = null;
    }

    function closeContextAndCopy(text) {
        ResourceService.copyText(text);
        contextEntry = null;
    }

    function memoryText(kilobytes) {
        return ResourceService.formatBytesFromKb(kilobytes, 1);
    }

    function diskText(bytes) {
        const value = Math.max(0, Number(bytes) || 0);
        const units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
        let unitIndex = 0;
        let scaledValue = value;
        while (scaledValue >= 1024 && unitIndex < units.length - 1) {
            scaledValue /= 1024;
            unitIndex += 1;
        }
        if (unitIndex === 0)
            return Math.round(scaledValue) + " " + units[unitIndex];
        return scaledValue.toFixed(1) + " " + units[unitIndex];
    }

    function resetProcessScroll() {
        processList.retainedScrollOffset = 0;
        processList.positionViewAtBeginning();
    }

    function desktopEntryForProcess(name) {
        const query = String(name || "").toLocaleLowerCase();
        if (!query)
            return null;
        const direct = DesktopEntries.byId(query);
        if (direct)
            return direct;
        const candidate = DesktopEntries.heuristicLookup(query);
        if (!candidate)
            return null;
        const identity = [
            candidate.id,
            candidate.name,
            candidate.execString,
            candidate.startupClass
        ].filter(value => value).join(" ").toLocaleLowerCase();
        return identity.includes(query) ? candidate : null;
    }

    onActiveChanged: {
        setViewerActive(active);
        if (!active) {
            closeTransientUi();
            searchInput.clear();
            expandedPid = -1;
        }
    }

    Component.onDestruction: setViewerActive(false)

    component PanelText: AppText {
        color: panelPalette.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component Metric: RowLayout {
        required property string icon
        required property string label
        spacing: Appearance.px(4)

        AppText {
            text: parent.icon
            color: panelPalette.primary
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.px(18)
            }
        }

        PanelText {
            text: parent.label
            color: panelPalette.subtext
            font.pixelSize: Appearance.smallFontSize
        }
    }

    component ScopeButton: Rectangle {
        id: scopeButton

        required property string label
        required property bool selected
        signal clicked

        implicitWidth: scopeLabel.implicitWidth + Appearance.px(20)
        implicitHeight: Appearance.px(32)
        radius: Appearance.px(9)
        color: selected
            ? panelPalette.primaryContainer
            : scopeArea.containsMouse
                ? panelPalette.layer1Active : panelPalette.layer1
        border.width: selected ? 1 : 0
        border.color: panelPalette.primary

        PanelText {
            id: scopeLabel
            anchors.centerIn: parent
            text: scopeButton.label
            color: scopeButton.selected
                ? panelPalette.primaryContainerText : panelPalette.layer1Text
            font.pixelSize: Appearance.smallFontSize
        }

        MouseArea {
            id: scopeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: scopeButton.clicked()
        }
    }

    component DiskSwitchButton: Rectangle {
        id: diskSwitchButton

        required property string icon
        signal clicked

        implicitWidth: Appearance.px(30)
        implicitHeight: Appearance.px(30)
        radius: Appearance.px(9)
        color: diskSwitchArea.containsMouse && enabled
            ? panelPalette.layer1Active : panelPalette.layer1
        opacity: enabled ? 1 : 0.38

        AppText {
            anchors.centerIn: parent
            text: diskSwitchButton.icon
            color: panelPalette.layer1Text
            font {
                family: Appearance.iconFontFamily
                weight: Font.Normal
                pixelSize: Appearance.px(14)
            }
        }

        MouseArea {
            id: diskSwitchArea
            anchors.fill: parent
            enabled: diskSwitchButton.enabled
            hoverEnabled: true
            cursorShape: enabled
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: diskSwitchButton.clicked()
        }
    }

    component NetworkRateCard: Rectangle {
        id: networkRateCard

        required property string icon
        required property string label
        required property real bytesPerSecond

        Layout.preferredWidth: Appearance.px(220)
        implicitHeight: Appearance.px(60)
        radius: Appearance.px(12)
        color: panelPalette.layer1
        border.width: 1
        border.color: panelPalette.layer0Border

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(9)
                rightMargin: Appearance.px(11)
            }
            spacing: Appearance.px(10)

            Rectangle {
                implicitWidth: Appearance.px(30)
                implicitHeight: Appearance.px(30)
                radius: Appearance.fullRadius
                color: panelPalette.primaryContainer

                AppText {
                    anchors.centerIn: parent
                    text: networkRateCard.icon
                    color: panelPalette.primaryContainerText
                    font {
                        family: Appearance.iconFontFamily
                        weight: Font.Normal
                        pixelSize: Appearance.px(15)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(1)

                PanelText {
                    text: networkRateCard.label
                    color: panelPalette.subtext
                    font.pixelSize: Appearance.smallFontSize
                }

                PanelText {
                    Layout.fillWidth: true
                    text: ResourceService.formatRate(
                        networkRateCard.bytesPerSecond)
                    color: panelPalette.layer0Text
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    component MenuAction: Rectangle {
        id: menuAction

        required property string icon
        required property string label
        property bool destructive: false
        signal triggered

        implicitWidth: Appearance.px(214)
        implicitHeight: Appearance.px(38)
        radius: Appearance.px(8)
        color: menuArea.containsMouse && enabled
            ? panelPalette.layer1Active : "transparent"
        opacity: enabled ? 1 : 0.42

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(10)
                rightMargin: Appearance.px(10)
            }
            spacing: Appearance.px(9)

            AppText {
                text: menuAction.icon
                color: menuAction.destructive
                    ? panelPalette.error : panelPalette.primary
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(15)
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: menuAction.label
                color: menuAction.destructive
                    ? panelPalette.error : panelPalette.layer0Text
                font.pixelSize: Appearance.smallFontSize
            }
        }

        MouseArea {
            id: menuArea
            anchors.fill: parent
            enabled: menuAction.enabled
            hoverEnabled: true
            cursorShape: enabled
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: menuAction.triggered()
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(10)

        PopupHeader {
            useBarPalette: root.useBarPalette
            icon: "󰍛"
            title: I18n.tr("systemMonitor")
            showActions: ResourceService.actionMessage.length > 0

            PanelText {
                text: ResourceService.actionMessage
                color: panelPalette.subtext
                font.pixelSize: Appearance.smallFontSize
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(10)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(104)
                radius: Appearance.smallRadius
                color: panelPalette.layer3
                border.width: 1
                border.color: panelPalette.outline

                RowLayout {
                    anchors {
                        fill: parent
                        margins: Appearance.px(13)
                    }
                    spacing: Appearance.px(12)

                    ResourceRing {
                        implicitSize: Appearance.px(46)
                        icon: "󰻠"
                        iconSize: 24
                        value: ResourceService.cpuUsage
                        warning: ResourceService.cpuUsage >= 0.9
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: Appearance.px(5)

                        PanelText {
                            Layout.fillWidth: true
                            text: ResourceService.cpuModel
                            color: panelPalette.layer0Text
                            elide: Text.ElideRight
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            spacing: Appearance.px(12)

                            Metric {
                                icon: "󰓅"
                                label: ResourceService.cpuFrequencyGhz > 0
                                    ? ResourceService.cpuFrequencyGhz
                                        .toFixed(2) + " GHz" : "-- GHz"
                            }

                            Metric {
                                icon: "󰔏"
                                label: ResourceService.temperatureAvailable
                                    ? Math.round(
                                        ResourceService.cpuTemperature)
                                        + "°C" : "--°C"
                            }

                            Metric {
                                icon: "󰇄"
                                label: Math.round(
                                    ResourceService.cpuUsage * 100) + "%"
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(104)
                radius: Appearance.smallRadius
                color: panelPalette.layer3
                border.width: 1
                border.color: panelPalette.outline

                RowLayout {
                    anchors {
                        fill: parent
                        margins: Appearance.px(13)
                    }
                    spacing: Appearance.px(12)

                    ResourceRing {
                        implicitSize: Appearance.px(46)
                        icon: "󰍛"
                        iconSize: 24
                        value: ResourceService.memoryUsage
                        warning: ResourceService.memoryUsage >= 0.9
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(5)

                        PanelText {
                            text: I18n.tr("memory")
                            color: panelPalette.layer0Text
                            font.weight: Font.DemiBold
                        }

                        RowLayout {
                            spacing: Appearance.px(12)

                            Metric {
                                icon: "󰋊"
                                label: I18n.tr("total") + " "
                                    + root.memoryText(
                                        ResourceService.memoryTotalKb)
                            }

                            Metric {
                                icon: "󰆼"
                                label: I18n.tr("used") + " "
                                    + root.memoryText(
                                        ResourceService.memoryUsedKb)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: filesystemCard

            readonly property var filesystem:
                ResourceService.selectedFilesystem

            Layout.fillWidth: true
            implicitHeight: Appearance.px(82)
            radius: Appearance.smallRadius
            color: panelPalette.layer3
            border.width: 1
            border.color: panelPalette.outline

            WheelHandler {
                enabled: ResourceService.filesystems.length > 1
                acceptedDevices: PointerDevice.Mouse
                    | PointerDevice.TouchPad
                onWheel: event => {
                    ResourceService.selectFilesystemRelative(
                        event.angleDelta.y < 0 ? 1 : -1);
                    event.accepted = true;
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(14)
                    rightMargin: Appearance.px(14)
                }
                spacing: Appearance.px(10)

                ResourceRing {
                    implicitSize: Appearance.px(46)
                    icon: "󰋊"
                    iconSize: 22
                    value: filesystemCard.filesystem?.usage ?? 0
                    warning: (filesystemCard.filesystem?.usage ?? 0) >= 0.9
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: Appearance.px(2)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.px(10)

                        PanelText {
                            text: filesystemCard.filesystem
                                ? I18n.tr("disk") + "  "
                                    + filesystemCard.filesystem.target
                                : I18n.tr("noFilesystems")
                            color: panelPalette.layer0Text
                            elide: Text.ElideMiddle
                            font.weight: Font.DemiBold
                        }

                        PanelText {
                            Layout.fillWidth: true
                            text: (
                                filesystemCard.filesystem.totalBytes > 0
                                    ? filesystemCard.filesystem.usedBytes
                                        / filesystemCard.filesystem.totalBytes
                                        * 100
                                    : 0
                            ).toFixed(1) + "%"
                            color: panelPalette.subtext
                        }
                    }

                    PanelText {
                        Layout.fillWidth: true
                        text: filesystemCard.filesystem
                            ? filesystemCard.filesystem.filesystemType
                                .toLocaleUpperCase()
                                + "  ·  "
                                + filesystemCard.filesystem.source
                            : ResourceService.filesystemError
                        color: panelPalette.subtext
                        elide: Text.ElideMiddle
                        font.pixelSize: Appearance.smallFontSize
                    }
                }

                Metric {
                    visible: filesystemCard.filesystem !== null
                    icon: "󰆼"
                    label: I18n.tr("used") + " "
                        + root.diskText(
                            filesystemCard.filesystem?.usedBytes ?? 0)
                        + "  /  "
                        + root.diskText(
                            filesystemCard.filesystem?.totalBytes ?? 0)
                }

                DiskSwitchButton {
                    icon: "󰅁"
                    enabled: ResourceService.filesystems.length > 1
                    onClicked:
                        ResourceService.selectFilesystemRelative(-1)
                }

                PanelText {
                    Layout.preferredWidth: Appearance.px(42)
                    text: ResourceService.filesystems.length > 0
                        ? (ResourceService.selectedFilesystemIndex + 1)
                            + "/" + ResourceService.filesystems.length
                        : "0/0"
                    color: panelPalette.subtext
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.smallFontSize
                }

                DiskSwitchButton {
                    icon: "󰅂"
                    enabled: ResourceService.filesystems.length > 1
                    onClicked:
                        ResourceService.selectFilesystemRelative(1)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(82)
            radius: Appearance.smallRadius
            color: panelPalette.layer3
            border.width: 1
            border.color: panelPalette.outline

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(14)
                    rightMargin: Appearance.px(14)
                }
                spacing: Appearance.px(12)

                Rectangle {
                    implicitWidth: Appearance.px(46)
                    implicitHeight: Appearance.px(46)
                    radius: Appearance.fullRadius
                    color: panelPalette.primaryContainer

                    AppText {
                        anchors.centerIn: parent
                        text: "󰛳"
                        color: panelPalette.primaryContainerText
                        font {
                            family: Appearance.iconFontFamily
                            weight: Font.Normal
                            pixelSize: Appearance.px(21)
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PanelText {
                        text: I18n.tr("networkSpeed")
                        color: panelPalette.layer0Text
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        text: ResourceService.networkInterface
                            || I18n.tr("unknown")
                        color: panelPalette.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }
                }

                NetworkRateCard {
                    icon: "󰁅"
                    label: I18n.tr("download")
                    bytesPerSecond:
                        ResourceService.downloadBytesPerSecond
                }

                NetworkRateCard {
                    icon: "󰁝"
                    label: I18n.tr("upload")
                    bytesPerSecond:
                        ResourceService.uploadBytesPerSecond
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.smallRadius
            color: panelPalette.layer3
            border.width: 1
            border.color: panelPalette.outline

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(10)
                }
                spacing: Appearance.px(7)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.px(7)

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Appearance.px(36)
                        radius: Appearance.px(10)
                        color: panelPalette.layer1
                        border.width: searchInput.activeFocus ? 1 : 0
                        border.color: panelPalette.primary

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(10)
                                rightMargin: Appearance.px(8)
                            }
                            spacing: Appearance.px(7)

                            AppText {
                                text: "󰍉"
                                color: searchInput.activeFocus
                                    ? panelPalette.primary
                                    : panelPalette.subtext
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(15)
                                }
                            }

                            AppTextField {
                                id: searchInput
                                Layout.fillWidth: true
                                padding: 0
                                placeholderText:
                                    I18n.tr("searchProcesses")
                                color: panelPalette.layer0Text
                                placeholderTextColor: panelPalette.subtext
                                selectionColor: panelPalette.primary
                                selectedTextColor: panelPalette.onPrimary
                                selectByMouse: true
                                background: null
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.smallFontSize
                                }
                                Keys.onEscapePressed: clear()
                                onTextChanged: root.resetProcessScroll()
                            }

                            AppText {
                                visible: searchInput.text.length > 0
                                text: "󰅖"
                                color: clearSearchArea.containsMouse
                                    ? panelPalette.primary
                                    : panelPalette.subtext
                                font {
                                    family: Appearance.iconFontFamily
                                    weight: Font.Normal
                                    pixelSize: Appearance.px(13)
                                }

                                MouseArea {
                                    id: clearSearchArea
                                    anchors.fill: parent
                                    anchors.margins: -Appearance.px(5)
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: searchInput.clear()
                                }
                            }
                        }
                    }

                    ScopeButton {
                        label: I18n.tr("allProcesses")
                        selected: root.processScope === "all"
                        onClicked: {
                            root.processScope = "all";
                            root.resetProcessScroll();
                        }
                    }

                    ScopeButton {
                        label: I18n.tr("userProcesses")
                        selected: root.processScope === "user"
                        onClicked: {
                            root.processScope = "user";
                            root.resetProcessScroll();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.px(9)
                    Layout.rightMargin: Appearance.px(12)
                    spacing: Appearance.px(8)

                    PanelText {
                        Layout.fillWidth: true
                        text: I18n.tr("name")
                        color: panelPalette.subtext
                        font.weight: Font.DemiBold
                    }

                    PanelText {
                        Layout.preferredWidth: Appearance.px(86)
                        text: "CPU" + root.sortArrow("cpu")
                        color: root.sortKey === "cpu"
                            ? panelPalette.primary : panelPalette.subtext
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.DemiBold

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -Appearance.px(6)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setSort("cpu")
                        }
                    }

                    PanelText {
                        Layout.preferredWidth: Appearance.px(112)
                        text: "PSS" + root.sortArrow("memory")
                        color: root.sortKey === "memory"
                            ? panelPalette.primary : panelPalette.subtext
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.DemiBold

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -Appearance.px(6)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setSort("memory")
                        }
                    }

                    PanelText {
                        Layout.preferredWidth: Appearance.px(76)
                        text: "PID"
                        color: panelPalette.subtext
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.preferredWidth: Appearance.px(18)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: panelPalette.outline
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: processList

                        property real retainedScrollOffset: 0

                        function rememberScrollPosition() {
                            retainedScrollOffset = Math.max(
                                0, contentY - originY);
                        }

                        function restoreScrollPosition() {
                            const maximumOffset = Math.max(
                                0, contentHeight - height);
                            contentY = originY + Math.min(
                                retainedScrollOffset, maximumOffset);
                        }

                        anchors.fill: parent
                        visible: count > 0
                        clip: true
                        spacing: Appearance.px(5)
                        model: root.filteredProcesses
                        boundsBehavior: Flickable.StopAtBounds

                        onMovementEnded: {
                            if (!ResourceService.processRefreshing)
                                rememberScrollPosition();
                        }

                        Connections {
                            target: ResourceService

                            function onProcessRefreshingChanged() {
                                if (ResourceService.processRefreshing) {
                                    processList.rememberScrollPosition();
                                } else {
                                    Qt.callLater(() =>
                                        processList.restoreScrollPosition());
                                }
                            }
                        }

                        Controls.ScrollBar.vertical: Controls.ScrollBar {
                            policy: Controls.ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            id: processEntry

                            required property var modelData
                            property var desktopEntry:
                                root.desktopEntryForProcess(
                                    modelData.name)
                            readonly property bool expanded:
                                root.expandedPid === modelData.pid

                            width: ListView.view.width
                                - Appearance.px(7)
                            height: expanded
                                ? Appearance.px(116)
                                : Appearance.px(52)
                            radius: Appearance.px(11)
                            color: processArea.containsMouse
                                || expanded
                                ? panelPalette.layer1Hover
                                : panelPalette.layer1
                            border.width: expanded ? 1 : 0
                            border.color: panelPalette.primary
                            clip: true

                            MouseArea {
                                id: processArea
                                anchors.fill: parent
                                acceptedButtons:
                                    Qt.LeftButton | Qt.RightButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: event => {
                                    if (event.button === Qt.RightButton) {
                                        root.openContextMenu(
                                            processEntry.modelData,
                                            processEntry,
                                            event.x, event.y);
                                    } else {
                                        root.expandedPid =
                                            processEntry.expanded
                                            ? -1
                                            : processEntry.modelData.pid;
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors {
                                    fill: parent
                                    margins: Appearance.px(8)
                                }
                                spacing: Appearance.px(6)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.px(8)

                                    Item {
                                        implicitWidth: Appearance.px(28)
                                        implicitHeight: Appearance.px(28)

                                        IconImage {
                                            id: processIcon
                                            anchors.fill: parent
                                            asynchronous: true
                                            visible:
                                                processEntry.desktopEntry
                                                    !== null
                                            source: visible
                                                ? Quickshell.iconPath(
                                                    processEntry
                                                        .desktopEntry.icon,
                                                    "application-x-executable")
                                                : ""
                                            opacity: ShellSettings
                                                    .monochromeAppIconsActive
                                                ? Appearance
                                                    .monochromeAppIconOpacity
                                                : 1
                                            layer.enabled:
                                                ShellSettings
                                                    .monochromeAppIconsActive
                                            layer.effect: MultiEffect {
                                                saturation: -1
                                                brightness: 0.12
                                                contrast: 0.08
                                            }
                                        }

                                        AppText {
                                            anchors.centerIn: parent
                                            visible: !processIcon.visible
                                            text: "󰒓"
                                            color: panelPalette.primary
                                            font {
                                                family:
                                                    Appearance.iconFontFamily
                                                weight: Font.Normal
                                                pixelSize:
                                                    Appearance.px(17)
                                            }
                                        }
                                    }

                                    PanelText {
                                        Layout.fillWidth: true
                                        text: processEntry.modelData.name
                                        color: panelPalette.layer0Text
                                        elide: Text.ElideRight
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        Layout.preferredWidth:
                                            Appearance.px(86)
                                        implicitHeight: Appearance.px(30)
                                        radius: Appearance.fullRadius
                                        color: panelPalette.layer1Active

                                        PanelText {
                                            anchors.centerIn: parent
                                            text: processEntry.modelData.cpu
                                                .toFixed(1) + "%"
                                            color: panelPalette.layer0Text
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth:
                                            Appearance.px(112)
                                        implicitHeight: Appearance.px(30)
                                        radius: Appearance.fullRadius
                                        color: processEntry.modelData.pssKb
                                                >= 1024 * 1024
                                            ? Theme.palette
                                                .m3tertiaryContainer
                                            : panelPalette.layer1Active

                                        PanelText {
                                            anchors.centerIn: parent
                                            text: root.memoryText(
                                                processEntry
                                                    .modelData.pssKb)
                                            color: processEntry.modelData
                                                    .pssKb >= 1024 * 1024
                                                ? Theme.palette
                                                    .m3onTertiaryContainer
                                                : panelPalette.layer0Text
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    PanelText {
                                        Layout.preferredWidth:
                                            Appearance.px(76)
                                        text: processEntry.modelData.pid
                                        color: panelPalette.subtext
                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }

                                    AppText {
                                        Layout.preferredWidth:
                                            Appearance.px(18)
                                        text: processEntry.expanded
                                            ? "󰅃" : "󰅀"
                                        color: panelPalette.subtext
                                        font {
                                            family:
                                                Appearance.iconFontFamily
                                            weight: Font.Normal
                                            pixelSize: Appearance.px(14)
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: processEntry.expanded
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Appearance.px(8)
                                    color: panelPalette.layer2

                                    ColumnLayout {
                                        anchors {
                                            fill: parent
                                            margins: Appearance.px(8)
                                        }
                                        spacing: Appearance.px(3)

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Appearance.px(6)

                                            PanelText {
                                                Layout.fillWidth: true
                                                text: I18n.tr("fullCommand")
                                                    + ":  "
                                                    + processEntry
                                                        .modelData.command
                                                color:
                                                    panelPalette.layer0Text
                                                elide: Text.ElideRight
                                                font.pixelSize:
                                                    Appearance.smallFontSize
                                            }

                                            AppText {
                                                text: "󰆏"
                                                color:
                                                    copyCommandArea
                                                        .containsMouse
                                                    ? panelPalette.primary
                                                    : panelPalette.subtext
                                                font {
                                                    family: Appearance
                                                        .iconFontFamily
                                                    pixelSize:
                                                        Appearance.px(14)
                                                }

                                                MouseArea {
                                                    id: copyCommandArea
                                                    anchors.fill: parent
                                                    anchors.margins:
                                                        -Appearance.px(5)
                                                    hoverEnabled: true
                                                    cursorShape:
                                                        Qt.PointingHandCursor
                                                    onClicked:
                                                        ResourceService
                                                            .copyText(
                                                                processEntry
                                                                    .modelData
                                                                    .command)
                                                }
                                            }
                                        }

                                        PanelText {
                                            text: "PPID: "
                                                + processEntry.modelData.ppid
                                                + "    PSS: "
                                                + root.memoryText(
                                                    processEntry.modelData
                                                        .pssKb)
                                                + "  ("
                                                + processEntry.modelData
                                                    .memoryPercent.toFixed(1)
                                                + "%)"
                                            color: panelPalette.subtext
                                            font.pixelSize:
                                                Appearance.smallFontSize
                                        }
                                    }
                                }
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: Appearance.fastDuration
                                    easing.type: Easing.OutCubic
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
                        visible: processList.count === 0
                            && !ResourceService.processRefreshing
                        spacing: Appearance.px(7)

                        AppText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰘦"
                            color: panelPalette.primary
                            font {
                                family: Appearance.iconFontFamily
                                weight: Font.Normal
                                pixelSize: Appearance.px(32)
                            }
                        }

                        PanelText {
                            Layout.alignment: Qt.AlignHCenter
                            text: searchInput.text
                                ? I18n.tr("noSearchResults")
                                : I18n.tr("noProcesses")
                            color: panelPalette.subtext
                        }
                    }

                    Controls.BusyIndicator {
                        anchors.centerIn: parent
                        visible: ResourceService.processRefreshing
                            && processList.count === 0
                        running: visible
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 90
        visible: root.contextEntry !== null
        onClicked: root.contextEntry = null
    }

    Rectangle {
        z: 91
        visible: root.contextEntry !== null
        x: root.contextX
        y: root.contextY
        width: Appearance.px(230)
        implicitHeight: contextColumn.implicitHeight
            + Appearance.px(12)
        radius: Appearance.px(12)
        color: panelPalette.layer2
        border.width: 1
        border.color: panelPalette.outline

        ColumnLayout {
            id: contextColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Appearance.px(6)
            }
            spacing: 0

            MenuAction {
                icon: "#"
                label: I18n.tr("copyProcessId")
                onTriggered: root.closeContextAndCopy(
                    root.contextEntry.pid)
            }

            MenuAction {
                icon: "󰆏"
                label: I18n.tr("copyProcessName")
                onTriggered: root.closeContextAndCopy(
                    root.contextEntry.name)
            }

            MenuAction {
                icon: "󰆍"
                label: I18n.tr("copyFullCommand")
                onTriggered: root.closeContextAndCopy(
                    root.contextEntry.command)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.px(8)
                Layout.rightMargin: Appearance.px(8)
                implicitHeight: 1
                color: panelPalette.outline
            }

            MenuAction {
                icon: "󰅖"
                label: I18n.tr("endProcess")
                destructive: true
                enabled: root.contextEntry?.canSignal ?? false
                onTriggered: {
                    ResourceService.signalProcess(
                        root.contextEntry.pid, false);
                    root.contextEntry = null;
                }
            }

            MenuAction {
                icon: "󰚌"
                label: I18n.tr("forceStopProcess")
                destructive: true
                enabled: root.contextEntry?.canSignal ?? false
                onTriggered: {
                    root.confirmEntry = root.contextEntry;
                    root.contextEntry = null;
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 100
        visible: root.confirmEntry !== null
        color: Appearance.withAlpha(
            panelPalette.scrim, 0.55)

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            anchors.centerIn: parent
            width: Appearance.px(390)
            implicitHeight: confirmColumn.implicitHeight
                + Appearance.px(28)
            radius: Appearance.normalRadius
            color: panelPalette.layer2
            border.width: 1
            border.color: panelPalette.outline

            ColumnLayout {
                id: confirmColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.px(14)
                }
                spacing: Appearance.px(10)

                PanelText {
                    Layout.fillWidth: true
                    text: I18n.tr("confirmForceStop")
                    color: panelPalette.layer0Text
                    font {
                        pixelSize: Appearance.largeFontSize
                        weight: Font.DemiBold
                    }
                }

                PanelText {
                    Layout.fillWidth: true
                    text: root.confirmEntry
                        ? root.confirmEntry.name + "  (PID "
                            + root.confirmEntry.pid + ")" : ""
                    color: panelPalette.subtext
                    elide: Text.ElideRight
                }

                PanelText {
                    Layout.fillWidth: true
                    text: I18n.tr("forceStopWarning")
                    color: panelPalette.error
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.smallFontSize
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    ScopeButton {
                        label: I18n.tr("cancel")
                        selected: false
                        onClicked: root.confirmEntry = null
                    }

                    Rectangle {
                        implicitWidth: forceLabel.implicitWidth
                            + Appearance.px(22)
                        implicitHeight: Appearance.px(34)
                        radius: Appearance.px(9)
                        color: forceArea.containsMouse
                            ? panelPalette.error
                            : panelPalette.errorContainer

                        PanelText {
                            id: forceLabel
                            anchors.centerIn: parent
                            text: I18n.tr("forceStop")
                            color: forceArea.containsMouse
                                ? panelPalette.onError
                                : panelPalette.onErrorContainer
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: forceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ResourceService.signalProcess(
                                    root.confirmEntry.pid, true);
                                root.confirmEntry = null;
                            }
                        }
                    }
                }
            }
        }
    }
}
