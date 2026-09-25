pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.common.widgets

Item {
    id: root

    required property bool active
    required property real revealProgress
    signal closeRequested

    // Glass mode follows the shell's fixed dark glass palette. Without it,
    // Spotlight follows the regular light/dark theme.
    readonly property bool glassMode: ShellSettings.barFrostedGlass
    readonly property bool dark: glassMode || Theme.darkMode
    readonly property color primaryText: glassMode
        ? "#f5f5f7" : Appearance.layer1Text
    readonly property color secondaryText: glassMode
        ? "#a9abb2" : Appearance.subtext
    readonly property color glassBase: dark ? "#1c1d21" : "#f7f8fa"
    readonly property color white: "#ffffff"
    readonly property color black: "#000000"
    readonly property color surfaceColor: glassMode
        ? Appearance.withAlpha(glassBase, 0.68) : Appearance.layer1
    readonly property color surfaceBorder: glassMode
        ? Appearance.withAlpha(white, 0.12) : Appearance.layer0Border
    readonly property color accentColor: glassMode
        ? Appearance.barPrimary : Appearance.primary
    readonly property color textSelectionColor: glassMode
        ? Appearance.barPrimaryContainer : Appearance.primary
    readonly property color textSelectionTextColor: glassMode
        ? Appearance.barPrimaryContainerText : Theme.palette.m3onPrimary
    readonly property color selectedColor: glassMode
        ? Appearance.barLayer1Active : Appearance.primaryContainer
    readonly property color hoveredColor: glassMode
        ? Appearance.barLayer1Hover
        : Appearance.mix(Appearance.layer1,
            Appearance.primaryContainer, 0.58)
    readonly property color idleResultColor:
        Appearance.withAlpha(hoveredColor, 0)
    readonly property color selectedTextColor: glassMode
        ? Appearance.barLayer0Text : Appearance.primaryContainerText
    readonly property color selectedSecondaryTextColor:
        Appearance.withAlpha(selectedTextColor, 0.72)
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
            }).map(result => result.entry);
    }

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
        if (resultList.count <= 0)
            return;
        const index = Math.max(0, resultList.currentIndex);
        launch(filteredApplications[index]);
    }

    function moveSelection(offset) {
        if (resultList.count <= 0)
            return;
        const current = Math.max(0, resultList.currentIndex);
        resultList.currentIndex = Math.max(0,
            Math.min(resultList.count - 1, current + offset));
        resultList.positionViewAtIndex(
            resultList.currentIndex, ListView.Contain);
    }

    function focusSearch() {
        searchInput.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function resetSelection() {
        resultList.currentIndex = filteredApplications.length > 0 ? 0 : -1;
        resultList.positionViewAtBeginning();
    }

    onActiveChanged: {
        if (!active)
            return;
        searchInput.clear();
        resetSelection();
        Qt.callLater(focusSearch);
    }

    onFilteredApplicationsChanged: Qt.callLater(resetSelection)

    component GlassSurface: Rectangle {
        radius: Appearance.px(24)
        color: root.surfaceColor
        border.width: 1
        border.color: root.surfaceBorder
        clip: true
        layer.enabled: ShellSettings.shadowEnabled
            && root.revealProgress > 0.001
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowBlur: 1
            blurMax: Math.max(1, Math.round(Math.min(
                ShellSettings.shadowBlurRadius, 18) * Appearance.scale))
            shadowColor: Appearance.withAlpha(root.black,
                Math.min(0.5, ShellSettings.shadowOpacity
                    * (root.dark ? 0.68 : 0.42)))
            shadowVerticalOffset: Math.round(
                Math.min(ShellSettings.shadowOffsetY + 2, 7)
                    * Appearance.scale)
        }

        Behavior on color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation { duration: Appearance.spatialDuration }
        }
        Behavior on border.color {
            enabled: !Theme.paletteTransitionRunning
            ColorAnimation { duration: Appearance.spatialDuration }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.glassMode
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Appearance.withAlpha(root.white,
                        root.dark ? 0.07 : 0.16)
                }
                GradientStop {
                    position: 0.38
                    color: Appearance.withAlpha(root.white, 0.012)
                }
                GradientStop {
                    position: 1
                    color: Appearance.withAlpha(root.black,
                        root.dark ? 0.10 : 0.035)
                }
            }
        }
    }

    opacity: revealProgress

    GlassSurface {
        id: searchSurface

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Appearance.px(14)
        }
        height: Appearance.px(56)
        radius: Appearance.px(18)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(18)
                rightMargin: Appearance.px(15)
            }
            spacing: Appearance.px(12)

            AppText {
                text: "󰍉"
                color: searchInput.activeFocus
                    ? root.accentColor : root.secondaryText
                font {
                    family: Appearance.iconFontFamily
                    weight: Font.Normal
                    pixelSize: Appearance.px(21)
                }

                Behavior on color {
                    ColorAnimation { duration: Appearance.fastDuration }
                }
            }

            AppTextField {
                id: searchInput

                Layout.fillWidth: true
                padding: 0
                placeholderText: I18n.tr("searchApplications")
                color: root.primaryText
                placeholderTextColor: root.secondaryText
                selectionColor: root.textSelectionColor
                selectedTextColor: root.textSelectionTextColor
                selectByMouse: true
                background: null
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(18)
                    weight: Font.Medium
                }
                Keys.priority: Keys.BeforeItem
                onTextChanged: Qt.callLater(root.resetSelection)

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) {
                        root.moveSelection(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.moveSelection(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageDown) {
                        root.moveSelection(5);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageUp) {
                        root.moveSelection(-5);
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
                implicitWidth: Appearance.px(24)
                implicitHeight: width
                radius: Appearance.fullRadius
                color: clearArea.containsMouse
                    ? Appearance.withAlpha(root.primaryText, 0.13)
                    : Appearance.withAlpha(root.primaryText, 0.07)

                AppText {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: root.secondaryText
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
                    onClicked: {
                        searchInput.clear();
                        root.focusSearch();
                    }
                }
            }
        }
    }

    GlassSurface {
        id: resultsSurface

        anchors {
            top: searchSurface.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: Appearance.px(9)
            leftMargin: Appearance.px(14)
            rightMargin: Appearance.px(14)
            bottomMargin: Appearance.px(14)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.px(42)
                Layout.leftMargin: Appearance.px(20)
                Layout.rightMargin: Appearance.px(20)

                AppText {
                    text: I18n.tr("spotlightResults")
                    color: root.primaryText
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                        weight: Font.DemiBold
                    }
                }

                Item { Layout.fillWidth: true }

                AppText {
                    text: I18n.tr("spotlightResultCount")
                        .arg(root.filteredApplications.length)
                    color: root.secondaryText
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Appearance.px(10)
                Layout.rightMargin: Appearance.px(10)

                ListView {
                    id: resultList

                    anchors.fill: parent
                    visible: count > 0
                    clip: true
                    model: root.filteredApplications
                    currentIndex: count > 0 ? 0 : -1
                    spacing: Appearance.px(3)
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: false
                    reuseItems: true
                    cacheBuffer: Appearance.px(128)
                    onCountChanged: Qt.callLater(root.resetSelection)

                    Controls.ScrollBar.vertical: Controls.ScrollBar {
                        policy: Controls.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: resultDelegate

                        required property var modelData
                        required property int index
                        readonly property bool selected:
                            index === resultList.currentIndex
                        readonly property bool highlighted:
                            selected || resultArea.containsMouse

                        width: resultList.width
                            - (resultList.contentHeight > resultList.height
                                ? Appearance.px(8) : 0)
                        height: Appearance.px(54)
                        radius: Appearance.px(13)
                        color: selected ? root.selectedColor
                            : resultArea.containsMouse
                                ? root.hoveredColor
                                : root.idleResultColor

                        Behavior on color {
                            enabled: !Theme.paletteTransitionRunning
                            ColorAnimation {
                                duration: Appearance.fastDuration
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Appearance.px(12)
                                rightMargin: Appearance.px(13)
                            }
                            spacing: Appearance.px(12)

                            LauncherIcon {
                                iconSize: Appearance.px(38)
                                iconName: resultDelegate.modelData.icon
                                hovered: resultArea.containsMouse
                                pressed: resultArea.pressed
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                spacing: 0

                                AppText {
                                    Layout.fillWidth: true
                                    text: resultDelegate.modelData.name
                                    color: resultDelegate.highlighted
                                        ? root.selectedTextColor
                                        : root.primaryText
                                    elide: Text.ElideRight
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.fontSize
                                        weight: Font.DemiBold
                                    }
                                }

                                AppText {
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: resultDelegate.modelData.genericName
                                        || resultDelegate.modelData.comment || ""
                                    color: resultDelegate.highlighted
                                        ? root.selectedSecondaryTextColor
                                        : root.secondaryText
                                    elide: Text.ElideRight
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: Appearance.smallFontSize
                                    }
                                }
                            }

                            AppText {
                                visible: resultDelegate.highlighted
                                // text: "↵←"
                                color: Appearance.withAlpha(
                                    root.selectedTextColor, 0.78)
                                font {
                                    family: Appearance.fontFamily
                                    pixelSize: Appearance.px(18)
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: resultArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: resultList.currentIndex = resultDelegate.index
                            onClicked: root.launch(resultDelegate.modelData)
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: resultList.count === 0
                    spacing: Appearance.spacingSmall

                    AppText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍉"
                        color: Appearance.withAlpha(root.accentColor, 0.72)
                        font {
                            family: Appearance.iconFontFamily
                            weight: Font.Normal
                            pixelSize: Appearance.px(34)
                        }
                    }

                    AppText {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.tr("noApplicationsFound")
                        color: root.secondaryText
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.fontSize
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.px(16)
                Layout.rightMargin: Appearance.px(16)
                implicitHeight: 1
                color: Appearance.withAlpha(root.primaryText, 0.10)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.px(36)
                Layout.leftMargin: Appearance.px(20)
                Layout.rightMargin: Appearance.px(20)

                AppText {
                    text: I18n.tr("spotlight")
                    color: root.secondaryText
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                        weight: Font.Medium
                    }
                }

                Item { Layout.fillWidth: true }

                AppText {
                    text: I18n.tr("launcherNavigateHint") + "   "
                        + I18n.tr("launcherOpenHint") + "   "
                        + I18n.tr("launcherCloseHint")
                    color: root.secondaryText
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.smallFontSize
                    }
                }
            }
        }
    }
}
