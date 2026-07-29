pragma ComponentBehavior: Bound

import QtQuick
import qs.common

Item {
    id: root

    property string outputName: ""
    property Item activeItem: null
    property Item hoverItem: null
    readonly property real padding: Appearance.px(5)

    implicitWidth: workspaceRow.implicitWidth + padding * 2
    implicitHeight: Appearance.barHeight

    function refreshActiveItem() {
        for (let index = 0; index < workspaceRepeater.count; ++index) {
            const item = workspaceRepeater.itemAt(index);
            if (item?.onThisOutput && item.workspaceActive) {
                activeItem = item;
                return;
            }
        }
        // Niri can deliver the old and new workspace role updates separately.
        // Keep the previous item for that event-loop turn instead of flashing.
    }

    function beginHover(item) {
        hoverClear.stop();
        hoverItem = item;
    }

    function endHover(item) {
        if (hoverItem === item)
            hoverClear.restart();
    }

    onOutputNameChanged: activeRefresh.restart()

    Timer {
        id: activeRefresh

        interval: 0
        onTriggered: root.refreshActiveItem()
    }

    Timer {
        id: hoverClear

        interval: 0
        onTriggered: root.hoverItem = null
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: Appearance.px(4)
            bottomMargin: Appearance.px(4)
        }
        radius: Appearance.smallRadius
        color: Appearance.layer1
        border.width: 1
        border.color: Appearance.layer0Border
    }

    Item {
        id: content

        anchors {
            fill: parent
            margins: root.padding
        }

        Rectangle {
            id: activeIndicator

            z: 0
            visible: root.activeItem !== null && root.activeItem.visible
            x: root.activeItem
                ? workspaceRow.x + root.activeItem.x
                    + (root.activeItem.width - width) / 2
                : 0
            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.px(22)
            height: Appearance.px(22)
            radius: Appearance.fullRadius
            color: Appearance.secondaryContainer

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.spatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.spatialCurve
                }
            }
        }

        Rectangle {
            id: hoverIndicator

            z: 0.5
            visible: root.hoverItem !== null && root.hoverItem.visible
            x: root.hoverItem
                ? workspaceRow.x + root.hoverItem.x
                    + (root.hoverItem.width - width) / 2
                : 0
            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.px(22)
            height: Appearance.px(22)
            radius: Appearance.fullRadius
            color: root.hoverItem?.selected
                ? Appearance.mix(Appearance.secondaryContainer,
                    Appearance.secondaryContainerText, 0.12)
                : Appearance.layer1Hover
        }

        Row {
            id: workspaceRow

            z: 1
            anchors.centerIn: parent
            spacing: 0

            Repeater {
                id: workspaceRepeater

                model: NiriService.workspaces
                onCountChanged: activeRefresh.restart()

                delegate: Item {
                    id: workspaceDelegate

                    required property var model
                    readonly property bool onThisOutput:
                        model.output === root.outputName
                    readonly property bool workspaceActive: model.isActive
                    readonly property bool workspaceEmpty:
                        Number(model.activeWindowId) === 0
                    readonly property bool shouldShow: onThisOutput
                        && (ShellSettings.showEmptyWorkspaces
                            || !workspaceEmpty || workspaceActive)
                    readonly property bool selected:
                        root.activeItem === workspaceDelegate

                    visible: shouldShow
                    width: shouldShow ? Appearance.px(26) : 0
                    height: shouldShow ? Appearance.px(26) : 0

                    onWorkspaceActiveChanged: activeRefresh.restart()
                    onOnThisOutputChanged: activeRefresh.restart()
                    onShouldShowChanged: activeRefresh.restart()
                    Component.onCompleted: activeRefresh.restart()

                    Rectangle {
                        anchors.centerIn: parent
                        width: Appearance.px(22)
                        height: Appearance.px(22)
                        radius: Appearance.fullRadius
                        color: "transparent"
                        border.width: workspaceDelegate.model.isUrgent ? 1 : 0
                        border.color: Appearance.tertiary
                    }

                    Text {
                        anchors.centerIn: parent
                        text: model.name || model.index
                        color: workspaceDelegate.selected
                            ? Appearance.secondaryContainerText
                            : model.isUrgent
                                ? Appearance.tertiary : Appearance.subtext
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.smallFontSize
                            weight: workspaceDelegate.selected
                                ? Font.DemiBold : Font.Medium
                        }
                    }

                    MouseArea {
                        id: workspaceMouse

                        anchors.fill: parent
                        enabled: workspaceDelegate.onThisOutput
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.beginHover(workspaceDelegate)
                        onExited: root.endHover(workspaceDelegate)
                        onClicked: {
                            NiriService.focusWorkspaceById(
                                workspaceDelegate.model.id);
                        }
                    }
                }
            }
        }
    }
}
