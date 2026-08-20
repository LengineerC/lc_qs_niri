pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

// Horizontal adaptation of Caelestia's popouts/ClipWrapper + Wrapper.
// This item must live in the same layer-shell window as the bar.
Item {
    id: root

    readonly property Item popupMaskItem: root
    readonly property bool pointerInside: popupHover.hovered
        || page === "tray"
            && (dedicatedPanelLoader.item?.menuContainsMouse ?? false)
    readonly property int moveDuration: ShellSettings.animationDuration
    readonly property var moveCurve: ShellSettings.popupBezierCurve
    readonly property real targetX: {
        const screenWidth = parent?.width ?? popupWidth;
        const center = Number.isFinite(anchorCenterX)
            ? anchorCenterX : screenWidth / 2;
        const rawX = center - popupWidth / 2;
        const remaining = screenWidth - Math.floor(rawX + popupWidth);

        if (remaining < 0)
            return rawX + remaining;
        return Math.max(rawX, 0);
    }

    property Item anchorItem: null
    // Freeze the trigger's center while the popup is open. Dynamic bar
    // modules (especially media metadata) may resize or move without dragging
    // an already visible panel along with them.
    property real anchorCenterX: NaN
    property string outputName: ""
    property string page: ""
    property bool shown: false
    property real offsetScale: shown ? 0 : 1
    property var deformMatrix
    readonly property real revealProgress: {
        const progress = Math.max(0, Math.min(1, 1 - offsetScale));
        return progress < 0.008 ? 0 : progress;
    }

    property string popupIcon: "󰋼"
    property string popupTitle: ""
    property var popupRows: []
    property int popupBaseWidth: 340
    readonly property Component currentPanelComponent: {
        switch (page) {
        case "system": return systemPanelComponent;
        case "launcher": return launcherPanelComponent;
        case "resources": return resourcePanelComponent;
        case "battery": return batteryPanelComponent;
        case "power": return powerPanelComponent;
        case "weather": return weatherPanelComponent;
        case "calendar": return calendarPanelComponent;
        case "clipboard": return clipboardPanelComponent;
        case "notifications": return notificationPanelComponent;
        case "tray": return trayPanelComponent;
        case "media": return mediaPanelComponent;
        default: return null;
        }
    }
    readonly property int popupWidth: Appearance.px(popupBaseWidth)
    readonly property int popupHeight: {
        if (page === "launcher") {
            const availableHeight =
                (parent?.height ?? Appearance.px(720))
                    - Appearance.barHeight - Appearance.px(8);
            return Math.min(Appearance.px(600),
                Math.max(Appearance.px(390), availableHeight));
        }
        if (page === "resources") {
            return Math.min(Appearance.px(760),
                Math.max(Appearance.px(520),
                    (parent?.height ?? Appearance.px(800))
                        - Appearance.barHeight - Appearance.px(8)));
        }
        if (page === "system") {
            return Math.min(Appearance.px(680),
                Math.max(Appearance.px(420),
                    (parent?.height ?? Appearance.px(760))
                        - Appearance.barHeight - Appearance.px(8)));
        }
        if (page === "battery")
            return loadedPanelHeight(390) + 16;
        if (page === "power")
            return loadedPanelHeight(480) + 16;
        if (page === "weather")
            return loadedPanelHeight(430) + 16;
        if (page === "calendar")
            return loadedPanelHeight(440) + 16;
        if (page === "clipboard") {
            return Math.min(Appearance.px(620),
                Math.max(Appearance.px(390),
                    (parent?.height ?? Appearance.px(720))
                        - Appearance.barHeight - Appearance.px(8)));
        }
        if (page === "notifications") {
            return Math.min(Appearance.px(650),
                Math.max(Appearance.px(430),
                    (parent?.height ?? Appearance.px(760))
                        - Appearance.barHeight - Appearance.px(8)));
        }
        if (page === "tray")
            return loadedPanelHeight(160) + 16;
        if (page === "media") {
            const availableHeight =
                (parent?.height ?? Appearance.px(760))
                    - Appearance.barHeight - Appearance.px(8);
            return Math.min(availableHeight,
                Math.max(Appearance.px(260),
                    loadedPanelHeight(150) + Appearance.px(16)));
        }
        return popupLayout.implicitHeight + Appearance.px(36);
    }

    x: targetX
    y: Appearance.barHeight
    width: popupWidth
    height: popupContent.height * revealProgress
    visible: width > 0 && revealProgress > 0
    clip: true

    HoverHandler {
        id: popupHover
    }

    function configure(pageName) {
        page = pageName;
        switch (pageName) {
        case "launcher":
            popupIcon = "󰣇";
            popupTitle = I18n.tr("launcher");
            popupBaseWidth = 500;
            popupRows = [];
            break;
        case "resources":
            popupIcon = "󰍛";
            popupTitle = I18n.tr("systemMonitor");
            popupBaseWidth = 820;
            popupRows = [];
            break;
        case "workspaces":
            popupIcon = "󰕮";
            popupTitle = I18n.tr("workspaces");
            popupBaseWidth = 330;
            popupRows = [
                { icon: "󰮯", label: I18n.tr("currentWorkspace"),
                    value: "1" },
                { icon: "󰁍", label: I18n.tr("scrollOnBar"),
                    value: I18n.tr("switchAction") }
            ];
            break;
        case "calendar":
            popupIcon = "󰃭";
            popupTitle = I18n.locale.toString(
                new Date(), "dddd, MMMM dd");
            popupBaseWidth = 390;
            popupRows = [];
            break;
        case "status":
            popupIcon = "󰒓";
            popupTitle = I18n.tr("systemStatus");
            popupBaseWidth = 370;
            popupRows = [
                { icon: "󰤨", label: I18n.tr("network"),
                    value: I18n.tr("connected") },
                { icon: "󰂯", label: I18n.tr("bluetooth"),
                    value: I18n.tr("on") },
                { icon: "󰂚", label: I18n.tr("notifications"),
                    value: I18n.tr("noUnread") },
                { icon: "󰁹", label: I18n.tr("battery"), value: "100%" },
                { icon: "󰏘", label: I18n.tr("wallpaperPalette"),
                    value: Theme.generating ? I18n.tr("generating")
                        : Theme.scheme.replace("scheme-", "") }
            ];
            break;
        case "system":
            popupIcon = "󰒓";
            popupTitle = I18n.tr("networkDevices");
            popupBaseWidth = 650;
            popupRows = [];
            break;
        case "battery":
            popupIcon = BatteryService.powerIcon();
            popupTitle = BatteryService.panelTitle;
            popupBaseWidth = 420;
            popupRows = [];
            break;
        case "power":
            popupIcon = "󰐥";
            popupTitle = I18n.tr("powerMenu");
            popupBaseWidth = 410;
            popupRows = [];
            break;
        case "weather":
            popupIcon = WeatherService.currentIcon;
            popupTitle = I18n.tr("weather");
            popupBaseWidth = 850;
            popupRows = [];
            break;
        case "clipboard":
            popupIcon = "󰅇";
            popupTitle = I18n.tr("clipboard");
            popupBaseWidth = 520;
            popupRows = [];
            break;
        case "notifications":
            popupIcon = "󰂚";
            popupTitle = I18n.tr("notifications");
            popupBaseWidth = 590;
            popupRows = [];
            break;
        case "tray":
            popupIcon = "󰀻";
            popupTitle = I18n.tr("systemTray");
            popupBaseWidth = 330;
            popupRows = [];
            break;
        case "media":
            popupIcon = "󰝚";
            popupTitle = I18n.tr("media");
            popupBaseWidth = 570;
            popupRows = [];
            break;
        default:
            popupIcon = "󰝚";
            popupTitle = I18n.tr("media");
            popupBaseWidth = 370;
            popupRows = [
                { icon: "󰝚", label: I18n.tr("noMediaPlaying"),
                    value: "" },
                { icon: "󰐊", label: I18n.tr("playerControls"),
                    value: I18n.tr("unavailable") }
            ];
        }
    }

    function loadedPanelHeight(fallbackHeight) {
        return dedicatedPanelLoader.item?.implicitHeight
            ?? Appearance.px(fallbackHeight);
    }

    Component {
        id: systemPanelComponent

        SystemPanel {
            active: root.shown
            outputName: root.outputName
            onCloseRequested: root.close()
        }
    }

    Component {
        id: launcherPanelComponent

        LauncherPanel {
            active: root.shown
            onCloseRequested: root.close()
        }
    }

    Component {
        id: resourcePanelComponent

        ResourcePanel {
            active: root.shown
            onCloseRequested: root.close()
        }
    }

    Component {
        id: batteryPanelComponent

        BatteryPanel {
            onCloseRequested: root.close()
        }
    }

    Component {
        id: powerPanelComponent

        PowerPanel {
            onCloseRequested: root.close()
        }
    }

    Component {
        id: weatherPanelComponent

        WeatherPanel {
            active: root.shown
            onCloseRequested: root.close()
        }
    }

    Component {
        id: calendarPanelComponent

        CalendarPanel {
            onCloseRequested: root.close()
        }
    }

    Component {
        id: clipboardPanelComponent

        ClipboardPanel {
            onCloseRequested: root.close()
        }
    }

    Component {
        id: notificationPanelComponent

        NotificationPanel {
            active: root.shown
            onCloseRequested: root.close()
        }
    }

    Component {
        id: trayPanelComponent

        TrayPanel {
            active: root.shown
            onCloseRequested: root.close()
        }
    }

    Component {
        id: mediaPanelComponent

        MediaPanel {
            visualizerActive: root.revealProgress > 0
            onCloseRequested: root.close()
        }
    }

    function showFor(target, pageName) {
        if (shown && anchorItem === target && page === pageName) {
            close();
            return;
        }

        configure(pageName);
        anchorItem = target;
        if (target && parent) {
            const mappedCenter = target.mapToItem(
                parent, target.width / 2, 0).x;
            anchorCenterX = Number.isFinite(mappedCenter)
                ? mappedCenter : parent.width / 2;
        } else {
            anchorCenterX = (parent?.width ?? popupWidth) / 2;
        }
        shown = true;
    }

    function close() {
        shown = false;
    }

    Connections {
        target: I18n

        function onLanguageChanged() {
            if (root.page)
                root.configure(root.page);
        }
    }

    Behavior on offsetScale {
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.moveCurve
        }
    }

    Behavior on x {
        enabled: root.revealProgress > 0
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.moveCurve
        }
    }

    Behavior on width {
        enabled: root.revealProgress > 0
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.moveCurve
        }
    }

    Item {
        id: popupContent

        width: root.width
        height: root.popupHeight
        y: (-height - 5) * (1 - root.revealProgress)
        opacity: root.revealProgress
        transform: Matrix4x4 {
            matrix: root.deformMatrix
        }

        Behavior on height {
            enabled: root.revealProgress > 0
            NumberAnimation {
                duration: root.moveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.moveCurve
            }
        }

        Rectangle {
            id: innerSurface

            x: 7
            y: 7
            width: parent.width - 14
            height: root.popupHeight - 14
            radius: Appearance.smallRadius
            color: Appearance.layer2
            border.width: 1
            border.color: Appearance.layer0Border
        }

        ColumnLayout {
            id: popupLayout

            visible: root.currentPanelComponent === null
            x: Appearance.px(21)
            y: Appearance.px(18)
            width: parent.width - Appearance.px(42)
            spacing: Appearance.px(8)

            PopupHeader {
                icon: root.popupIcon
                iconColor: Appearance.layer1Text
                iconSize: Appearance.px(18)
                title: root.popupTitle
                titleColor: Appearance.layer1Text
                titleFontSize: Appearance.fontSize + Appearance.px(2)
                dividerSpacing: Appearance.px(8)
                onCloseClicked: root.close()
            }

            Repeater {
                model: root.popupRows

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Appearance.px(7)

                    Text {
                        text: modelData.icon
                        color: Appearance.layer1Text
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.fontSize + Appearance.px(3)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: Appearance.layer1Text
                        elide: Text.ElideRight
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.fontSize
                        }
                    }

                    Text {
                        text: modelData.value
                        color: Appearance.subtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                        }
                    }
                }
            }

        }

        Loader {
            id: dedicatedPanelLoader

            active: root.currentPanelComponent !== null
                && (root.shown || root.revealProgress > 0)
            asynchronous: false
            sourceComponent: root.currentPanelComponent
            anchors {
                fill: innerSurface
                margins: 1
            }
        }

    }
}
