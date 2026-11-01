pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.common.widgets

Item {
    id: root
    signal closeRequested()
    property string expandedGroup: "websites"
    SettingsPageHeader {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.pagePadding
        useBarPalette: SettingsPalette.glassMode
        icon: "󰘳"
        title: "Orbit"
        onCloseClicked: root.closeRequested()
    }
    ScrollView {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.pagePadding
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            width: parent.width
            spacing: Appearance.spacingMedium
            AppText {
                Layout.fillWidth: true
                text: I18n.tr("orbitSettingsHint")
                color: SettingsPalette.subtext
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.smallFontSize
            }
            OrbitGroupEditor {
                objectName: "orbitWebsiteSettings"
                Layout.fillWidth: true
                groupId: "websites"
                title: I18n.tr("orbitWebsites")
                subtitle: I18n.tr("orbitWebsitesSummary")
                icon: "󰖟"
                expanded: root.expandedGroup === groupId
                onToggleRequested: root.expandedGroup = expanded ? "" : groupId
            }
            OrbitGroupEditor {
                objectName: "orbitCommandSettings"
                Layout.fillWidth: true
                groupId: "tools"
                title: I18n.tr("orbitCommands")
                subtitle: I18n.tr("orbitCommandsSummary")
                icon: "󰞷"
                expanded: root.expandedGroup === groupId
                onToggleRequested: root.expandedGroup = expanded ? "" : groupId
            }
        }
    }
}
