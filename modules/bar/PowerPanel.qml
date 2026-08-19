pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.common.widgets
import qs.services

Item {
    id: root

    signal closeRequested

    implicitWidth: Appearance.px(410)
    implicitHeight: contentColumn.implicitHeight + Appearance.px(28)

    function perform(action) {
        closeRequested();
        Qt.callLater(() => {
            switch (action) {
            case "lock":
                LockService.lock();
                break;
            case "poweroff":
                UserService.powerOff();
                break;
            case "reboot":
                UserService.reboot();
                break;
            case "logout":
                UserService.logout();
                break;
            case "suspend":
                UserService.suspend();
                break;
            }
        });
    }

    component PanelText: Text {
        color: Appearance.layer1Text
        font {
            family: Appearance.fontFamily
            pixelSize: Appearance.fontSize
        }
    }

    component PowerAction: Rectangle {
        id: actionButton

        required property string action
        required property string icon
        required property string label
        property bool destructive: false
        property real holdProgress: 0
        property bool holdTriggered: false
        readonly property int holdDuration: 300
        readonly property bool hovered: actionHover.hovered

        Layout.fillWidth: true
        implicitHeight: Appearance.px(54)
        radius: Appearance.smallRadius
        // Keep the animated surface opaque. Animating from layer1 to an
        // alpha-only error color exposed the popup background mid-transition
        // and looked like a one-frame hover flash.
        color: hovered ? destructive ? Appearance.mix(Appearance.layer1, Theme.palette.m3error, 0.14) : Appearance.layer1Hover : Appearance.layer1
        border.width: 1
        border.color: hovered && destructive ? Theme.palette.m3error : Appearance.outline
        scale: actionPressArea.pressed ? 0.985 : 1

        function beginHold() {
            holdReset.stop();
            holdAnimation.stop();
            holdProgress = 0;
            holdTriggered = false;
            holdAnimation.restart();
        }

        function resetHold() {
            holdAnimation.stop();
            holdReset.stop();
            holdProgress = 0;
            holdTriggered = false;
        }

        function cancelHold() {
            if (holdTriggered)
                return;
            holdAnimation.stop();
            if (holdProgress > 0)
                holdReset.restart();
        }

        Item {
            anchors {
                fill: parent
                margins: 1
            }
            clip: true

            Item {
                width: parent.width * actionButton.holdProgress
                height: parent.height
                clip: true

                Rectangle {
                    width: actionButton.width - 2
                    height: parent.height
                    radius: Math.max(0, actionButton.radius - 1)
                    color: actionButton.destructive ? Appearance.mix(Appearance.layer1, Theme.palette.m3error, 0.32) : Appearance.primaryContainer
                }
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.px(15)
                rightMargin: Appearance.px(15)
            }
            spacing: Appearance.px(12)

            Rectangle {
                implicitWidth: Appearance.px(34)
                implicitHeight: Appearance.px(34)
                radius: Appearance.px(10)
                color: actionButton.destructive ? Appearance.withAlpha(Theme.palette.m3error, 0.14) : Appearance.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: actionButton.icon
                    color: actionButton.destructive ? Theme.palette.m3error : Appearance.primaryContainerText
                    font {
                        family: Appearance.iconFontFamily
                        pixelSize: Appearance.px(17)
                    }
                }
            }

            PanelText {
                Layout.fillWidth: true
                text: actionButton.label
                color: actionButton.destructive ? Theme.palette.m3error : Appearance.layer0Text
                font.weight: Font.DemiBold
            }

            Text {
                text: "󰅂"
                color: Appearance.subtext
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(15)
                }
            }
        }

        // Keep hover and press tracking independent. MouseArea.containsMouse
        // can briefly flip while an animated delegate is being re-evaluated,
        // which was visible as a flash on the destructive power-off action.
        HoverHandler {
            id: actionHover
            cursorShape: Qt.PointingHandCursor
        }

        MouseArea {
            id: actionPressArea

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            onPressed: actionButton.beginHold()
            onReleased: actionButton.cancelHold()
            onCanceled: actionButton.cancelHold()
            onPositionChanged: mouse => {
                if (pressed && (mouse.x < 0 || mouse.x > width || mouse.y < 0 || mouse.y > height))
                    actionButton.cancelHold();
            }
        }

        NumberAnimation {
            id: holdAnimation

            target: actionButton
            property: "holdProgress"
            from: 0
            to: 1
            duration: actionButton.holdDuration
            easing.type: Easing.Linear
            onFinished: {
                actionButton.holdTriggered = true;
                root.perform(actionButton.action);
                actionButton.resetHold();
            }
        }

        NumberAnimation {
            id: holdReset

            target: actionButton
            property: "holdProgress"
            to: 0
            duration: Appearance.fastDuration
            easing.type: Easing.OutCubic
        }

        onVisibleChanged: {
            if (!visible)
                resetHold();
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.fastDuration
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.fastDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Appearance.px(14)
        }
        spacing: Appearance.px(9)

        PopupHeader {
            icon: "󰐥"
            title: I18n.tr("powerMenu")
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Appearance.px(104)
            radius: Appearance.smallRadius
            color: Appearance.layer3
            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                anchors {
                    fill: parent
                    margins: Appearance.px(14)
                }
                spacing: Appearance.px(14)

                UserAvatar {
                    implicitSize: Appearance.px(72)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.px(3)

                    PanelText {
                        Layout.fillWidth: true
                        text: UserService.displayName
                        color: Appearance.layer0Text
                        elide: Text.ElideRight
                        font {
                            pixelSize: Appearance.largeFontSize
                            weight: Font.DemiBold
                        }
                    }

                    PanelText {
                        visible: UserService.loginName && UserService.loginName !== UserService.displayName
                        text: "@" + UserService.loginName
                        color: Appearance.subtext
                        font.pixelSize: Appearance.smallFontSize
                    }

                    RowLayout {
                        spacing: Appearance.px(6)

                        Text {
                            text: "󰥔"
                            color: Appearance.primary
                            font {
                                family: Appearance.iconFontFamily
                                pixelSize: Appearance.px(14)
                            }
                        }

                        PanelText {
                            text: I18n.tr("systemUptime") + " · " + UserService.formatUptime()
                            color: Appearance.subtext
                            font.pixelSize: Appearance.smallFontSize
                        }
                    }
                }
            }
        }

        PowerAction {
            action: "lock"
            icon: "󰌾"
            label: I18n.tr("lock")
        }

        PowerAction {
            action: "poweroff"
            icon: "󰐥"
            label: I18n.tr("shutDown")
            destructive: true
        }

        PowerAction {
            action: "reboot"
            icon: "󰜉"
            label: I18n.tr("restart")
        }

        PowerAction {
            action: "logout"
            icon: "󰍃"
            label: I18n.tr("logOut")
        }

        PowerAction {
            action: "suspend"
            icon: "󰤄"
            label: I18n.tr("suspend")
        }
    }
}
