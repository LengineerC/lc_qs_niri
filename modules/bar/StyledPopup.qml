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
    readonly property int moveDuration: ShellSettings.animationDuration
    readonly property var moveCurve: ShellSettings.popupBezierCurve
    readonly property real targetX: {
        const screenWidth = parent?.width ?? popupWidth;
        const center = anchorItem
            ? anchorItem.mapToItem(parent, anchorItem.width / 2, 0).x
            : screenWidth / 2;
        const rawX = center - popupWidth / 2;
        const remaining = screenWidth - Math.floor(rawX + popupWidth);

        if (remaining < 0)
            return rawX + remaining;
        return Math.max(rawX, 0);
    }

    property Item anchorItem: null
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
            return batteryPanel.implicitHeight + 16;
        if (page === "power")
            return powerPanel.implicitHeight + 16;
        if (page === "weather")
            return weatherPanel.implicitHeight + 16;
        if (page === "calendar")
            return calendarPanel.implicitHeight + 16;
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
        if (page === "media") {
            const availableHeight =
                (parent?.height ?? Appearance.px(760))
                    - Appearance.barHeight - Appearance.px(8);
            return Math.min(availableHeight,
                Math.max(Appearance.px(260),
                    mediaPanel.implicitHeight + Appearance.px(16)));
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

    function showFor(target, pageName) {
        if (shown && anchorItem === target && page === pageName) {
            close();
            return;
        }

        configure(pageName);
        anchorItem = target;
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

            visible: root.page !== "system" && root.page !== "battery"
                && root.page !== "power"
                && root.page !== "weather"
                && root.page !== "calendar" && root.page !== "clipboard"
                && root.page !== "notifications"
                && root.page !== "media" && root.page !== "launcher"
                && root.page !== "resources"
            x: Appearance.px(21)
            y: Appearance.px(18)
            width: parent.width - Appearance.px(42)
            spacing: Appearance.px(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(8)

                Text {
                    text: root.popupIcon
                    color: Appearance.layer1Text
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(18)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.popupTitle
                    color: Appearance.layer1Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.fontSize + Appearance.px(2)
                        weight: Font.DemiBold
                    }
                }

                CloseButton {
                    onClicked: root.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.outline
                opacity: 0.55
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

        SystemPanel {
            visible: root.page === "system"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        LauncherPanel {
            visible: root.page === "launcher"
            active: visible && root.shown
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        ResourcePanel {
            visible: root.page === "resources"
            active: visible && root.shown
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        BatteryPanel {
            id: batteryPanel

            visible: root.page === "battery"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        PowerPanel {
            id: powerPanel

            visible: root.page === "power"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        WeatherPanel {
            id: weatherPanel

            visible: root.page === "weather"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        CalendarPanel {
            id: calendarPanel

            visible: root.page === "calendar"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        ClipboardPanel {
            visible: root.page === "clipboard"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        NotificationPanel {
            visible: root.page === "notifications"
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

        MediaPanel {
            id: mediaPanel

            visible: root.page === "media"
            visualizerActive: root.page === "media"
                && root.revealProgress > 0
            anchors {
                fill: innerSurface
                margins: 1
            }
            onCloseRequested: root.close()
        }

    }
}
