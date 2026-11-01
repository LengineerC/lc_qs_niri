pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Rectangle {
    id: root
    required property string groupId
    required property string title
    required property string subtitle
    required property string icon
    property bool expanded: false
    signal toggleRequested()
    readonly property bool websites: groupId === "websites"
    readonly property int groupIndex: OrbitService.items.findIndex(item => item.id === groupId)
    readonly property bool available: OrbitService.configReady && groupIndex >= 0
    property string original: ""
    property string message: ""
    property bool dirty: false
    property bool submitting: false
    readonly property int entryCount: rows.count
    implicitHeight: heading.height + reveal.height
    radius: Appearance.cardRadius
    color: SettingsPalette.layer1
    border.color: expanded ? SettingsPalette.outline : SettingsPalette.layer0Border
    clip: true

    function reload() {
        if (!available || submitting) return;
        original = JSON.stringify(OrbitService.items);
        rows.clear();
        for (const item of OrbitService.items[groupIndex].children) {
            const kind = item.url !== undefined ? "url" : item.shell !== undefined ? "shell" : item.command ? "command" : "action";
            rows.append({label: item.name, value: kind === "command" ? JSON.stringify(item.command) : String(item[kind] || ""),
                description: String(item.desc || ""), glyph: String(item.icon || ""), kind: kind, raw: JSON.stringify(item)});
        }
        dirty = false;
        message = "";
    }
    function add() {
        if (!available || rows.count >= 8 || submitting) return;
        rows.append({label: "", value: "", description: "", glyph: "", kind: websites ? "url" : "shell", raw: "{}"});
        dirty = true;
        message = "";
    }
    function save() {
        message = "";
        try {
            const children = [];
            for (let i = 0; i < rows.count; ++i) {
                const row = rows.get(i), item = JSON.parse(row.raw);
                item.name = row.label.trim();
                item.desc = row.description.trim();
                item.icon = websites ? (row.glyph.trim() || "󰖟") : (item.icon || "󰞷");
                item[row.kind] = row.kind === "command" ? JSON.parse(row.value) : row.value.trim();
                children.push(item);
            }
            submitting = true;
            if (!OrbitService.saveGroup(groupIndex, children, original)) {
                submitting = false;
                message = OrbitService.error;
            }
        } catch (e) { submitting = false; message = String(e); }
    }
    Component.onCompleted: reload()
    Connections {
        target: OrbitService
        function onConfigReadyChanged() { if (!root.dirty) root.reload(); }
        function onItemsChanged() { if (!root.dirty && !root.submitting) Qt.callLater(root.reload); }
        function onConfigSaved() {
            if (!root.submitting) return;
            root.submitting = false;
            root.reload();
            root.message = I18n.tr("orbitSaved");
        }
        function onConfigSaveFailed(message) {
            if (!root.submitting) return;
            root.submitting = false;
            root.message = message;
        }
    }
    ListModel { id: rows }
    component Field: TextField {
        color: SettingsPalette.layer0Text
        placeholderTextColor: SettingsPalette.subtext
        font.pixelSize: Appearance.fontSize
        padding: Appearance.px(10)
        selectByMouse: true
        selectionColor: SettingsPalette.primaryContainer
        selectedTextColor: SettingsPalette.primaryContainerText
        background: Rectangle {
            radius: Appearance.fieldRadius
            color: SettingsPalette.layer2
            border.color: parent.activeFocus ? SettingsPalette.primary : SettingsPalette.outline
        }
    }
    Item {
        id: heading
        width: parent.width
        height: Appearance.px(90)
        Rectangle {
            anchors.fill: parent
            color: headerMouse.containsMouse ? SettingsPalette.layer1Hover : "transparent"
            radius: root.radius
        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.px(16)
            spacing: Appearance.spacingMedium
            Rectangle {
                Layout.preferredWidth: Appearance.px(44)
                Layout.preferredHeight: width
                radius: Appearance.px(14)
                color: root.expanded ? SettingsPalette.primaryContainer : SettingsPalette.layer2
                AppText {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.expanded ? SettingsPalette.primaryContainerText : SettingsPalette.primary
                    font.family: Appearance.iconFontFamily
                    font.pixelSize: Appearance.px(23)
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(4)
                AppText { text: root.title; color: SettingsPalette.layer0Text; font.pixelSize: Appearance.largeFontSize; font.weight: Font.DemiBold }
                AppText { Layout.fillWidth: true; text: root.subtitle; elide: Text.ElideRight; color: SettingsPalette.subtext; font.pixelSize: Appearance.smallFontSize }
            }
            AppText { text: root.entryCount + " / 8" + (root.dirty ? " ·" : ""); color: SettingsPalette.subtext; font.pixelSize: Appearance.smallFontSize }
            AppText {
                text: "󰅂"
                rotation: root.expanded ? 90 : 0
                font.family: Appearance.iconFontFamily
                font.pixelSize: Appearance.px(20)
                color: SettingsPalette.layer1Text
                Behavior on rotation { NumberAnimation { duration: Appearance.fastDuration; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested()
        }
    }
    Item {
        id: reveal
        anchors.top: heading.bottom
        width: parent.width
        property real progress: root.expanded ? 1 : 0
        height: body.implicitHeight * progress
        clip: true
        enabled: root.expanded
        visible: height > 0
        Behavior on progress { NumberAnimation { duration: Appearance.spatialDuration; easing.type: Easing.OutCubic } }
        ColumnLayout {
            id: body
            width: parent.width
            spacing: Appearance.spacingSmall
            Rectangle { Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; height: 1; color: SettingsPalette.outline }
            AppText {
                Layout.fillWidth: true
                Layout.margins: Appearance.px(16)
                text: !root.available ? I18n.tr("orbitUnavailable") : root.websites ? I18n.tr("orbitWebsiteHint") : I18n.tr("orbitCommandHint")
                wrapMode: Text.Wrap
                color: SettingsPalette.subtext
                font.pixelSize: Appearance.smallFontSize
            }
            Repeater {
                model: rows
                delegate: Rectangle {
                    id: row
                    required property int index
                    required property string label
                    required property string value
                    required property string kind
                    required property string description
                    required property string glyph
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.px(16)
                    Layout.rightMargin: Appearance.px(16)
                    implicitHeight: fields.implicitHeight + Appearance.px(24)
                    radius: Appearance.cardRadius
                    color: SettingsPalette.layer0
                    border.color: SettingsPalette.layer0Border
                    enabled: !root.submitting
                    ColumnLayout {
                        id: fields
                        anchors.fill: parent
                        anchors.margins: Appearance.px(12)
                        spacing: Appearance.px(8)
                        RowLayout {
                            Layout.fillWidth: true
                            AppText { text: String(row.index + 1).padStart(2, "0"); color: SettingsPalette.subtext; font.pixelSize: Appearance.smallFontSize }
                            Field {
                                Layout.fillWidth: true
                                objectName: "orbitItemName" + row.index
                                text: row.label
                                placeholderText: I18n.tr("orbitItemName")
                                onTextEdited: { rows.setProperty(row.index, "label", text); root.dirty = true; root.message = ""; }
                            }
                            ActionButton {
                                objectName: "orbitRemoveItem" + row.index
                                useBarPalette: SettingsPalette.glassMode
                                icon: "󰆴"; label: ""; compact: true; destructive: true
                                onClicked: { rows.remove(row.index); root.dirty = true; root.message = ""; }
                                StyledToolTip { useBarPalette: SettingsPalette.glassMode; text: I18n.tr("orbitDelete"); visible: removeHover.hovered }
                                HoverHandler { id: removeHover }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.websites
                            spacing: Appearance.px(8)
                            Rectangle {
                                Layout.preferredWidth: Appearance.px(44)
                                Layout.preferredHeight: Appearance.px(44)
                                radius: Appearance.fieldRadius
                                color: SettingsPalette.primaryContainer
                                AppText {
                                    anchors.centerIn: parent
                                    objectName: "orbitItemIconPreview" + row.index
                                    text: row.glyph.trim() || "󰖟"
                                    font.family: Appearance.iconFontFamily
                                    font.pixelSize: Appearance.px(24)
                                    color: SettingsPalette.primaryContainerText
                                }
                            }
                            Field {
                                Layout.fillWidth: true
                                objectName: "orbitItemIcon" + row.index
                                text: row.glyph
                                placeholderText: I18n.tr("orbitItemIcon")
                                onTextEdited: { rows.setProperty(row.index, "glyph", text); root.dirty = true; root.message = ""; }
                            }
                        }
                        Field {
                            Layout.fillWidth: true
                            objectName: "orbitItemDescription" + row.index
                            text: row.description
                            placeholderText: I18n.tr(root.websites ? "orbitItemDescription" : "orbitCommandDescription")
                            onTextEdited: { rows.setProperty(row.index, "description", text); root.dirty = true; root.message = ""; }
                        }
                        Field {
                            Layout.fillWidth: true
                            objectName: "orbitItemValue" + row.index
                            text: row.kind === "action" ? I18n.tr("orbitBuiltin") + row.value : row.value
                            readOnly: row.kind === "action"
                            placeholderText: root.websites ? "https://example.com" : "kitty --directory ~"
                            font.family: root.websites ? Appearance.fontFamily : Appearance.monospaceFontFamily
                            onTextEdited: { rows.setProperty(row.index, "value", text); root.dirty = true; root.message = ""; }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Appearance.px(16)
                spacing: Appearance.spacingSmall
                ActionButton {
                    objectName: "orbitAddItem"
                    useBarPalette: SettingsPalette.glassMode
                    icon: "󰐕"
                    label: I18n.tr(root.websites ? "orbitAddWebsite" : "orbitAddCommand")
                    enabled: root.available && rows.count < 8 && !root.submitting
                    onClicked: root.add()
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    useBarPalette: SettingsPalette.glassMode
                    icon: "󰑓"; label: I18n.tr("orbitReset")
                    enabled: root.dirty && !root.submitting
                    onClicked: root.reload()
                }
                ActionButton {
                    objectName: "orbitSaveItems"
                    useBarPalette: SettingsPalette.glassMode
                    icon: "󰆓"; label: I18n.tr(root.submitting ? "orbitSaving" : "orbitSave")
                    primary: true
                    enabled: root.dirty && !OrbitService.saving
                    onClicked: root.save()
                }
            }
            AppText {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.px(16)
                Layout.rightMargin: Appearance.px(16)
                Layout.bottomMargin: visible ? Appearance.px(16) : 0
                visible: text.length > 0
                text: root.message
                color: SettingsPalette.primary
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.smallFontSize
            }
        }
    }
}
