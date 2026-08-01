pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: root

    function addCurrentTask(): void {
        const value = taskInput.text.trim();
        if (!value)
            return;
        TodoService.addTask(value);
        taskInput.clear();
        taskInput.forceActiveFocus();
    }

    Layout.fillWidth: true
    implicitHeight: Appearance.px(175)
    radius: Appearance.px(24)
    color: Appearance.layer3
    border.width: 1
    border.color: Appearance.withAlpha(
        Appearance.outline, 0.58)
    clip: true

    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.px(10)
        }
        spacing: Appearance.px(7)

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.px(32)
            radius: Appearance.px(11)
            color: Appearance.layer1
            border.width: 1
            border.color: taskInput.activeFocus
                ? Appearance.withAlpha(Appearance.primary, 0.7)
                : Appearance.withAlpha(Appearance.outline, 0.4)

            MouseArea {
                anchors.fill: parent
                onClicked: forceActiveFocus()
            }

            Text {
                anchors {
                    left: parent.left
                    leftMargin: Appearance.px(9)
                    verticalCenter: parent.verticalCenter
                }
                text: "󰄬"
                color: Appearance.primary
                font {
                    family: Appearance.iconFontFamily
                    pixelSize: Appearance.px(14)
                }
            }

            TextInput {
                id: taskInput

                anchors {
                    left: parent.left
                    leftMargin: Appearance.px(30)
                    right: addButton.left
                    rightMargin: Appearance.px(4)
                    verticalCenter: parent.verticalCenter
                }
                color: Appearance.layer0Text
                selectionColor: Appearance.primaryContainer
                selectedTextColor: Appearance.primaryContainerText
                clip: true
                maximumLength: 160
                verticalAlignment: TextInput.AlignVCenter
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(11)
                }
                Keys.onReturnPressed: root.addCurrentTask()
                Keys.onEnterPressed: root.addCurrentTask()

                Text {
                    anchors.fill: parent
                    visible: taskInput.text.length === 0
                        && !taskInput.activeFocus
                    text: I18n.tr("addTask")
                    color: Appearance.subtext
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font: taskInput.font
                }
            }

            MouseArea {
                id: addButton

                anchors {
                    right: parent.right
                    rightMargin: Appearance.px(3)
                    verticalCenter: parent.verticalCenter
                }
                width: Appearance.px(27)
                height: Appearance.px(26)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.addCurrentTask()

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.px(9)
                    color: addButton.containsMouse
                        ? Appearance.primaryContainer
                        : Appearance.withAlpha(Appearance.primary, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Appearance.primary
                        font {
                            family: Appearance.monospaceFontFamily
                            pixelSize: Appearance.px(17)
                            weight: Font.Medium
                        }
                    }
                }
            }
        }

        ListView {
            id: taskList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.px(4)
            model: TodoService.tasks
            boundsBehavior: Flickable.StopAtBounds

            delegate: MouseArea {
                id: taskRow

                required property var modelData

                width: ListView.view.width
                height: Appearance.px(31)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: TodoService.toggleTask(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.px(10)
                    color: taskRow.containsMouse
                        ? Appearance.layer1Hover : "transparent"
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        leftMargin: Appearance.px(7)
                        verticalCenter: parent.verticalCenter
                    }
                    width: Appearance.px(17)
                    height: width
                    radius: Appearance.px(6)
                    color: taskRow.modelData.completed
                        ? Appearance.primary : "transparent"
                    border.width: 1
                    border.color: taskRow.modelData.completed
                        ? Appearance.primary : Appearance.outline

                    Text {
                        anchors.centerIn: parent
                        visible: taskRow.modelData.completed
                        text: "✓"
                        color: Theme.palette.m3onPrimary
                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.px(10)
                            weight: Font.Bold
                        }
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Appearance.px(31)
                        right: deleteButton.left
                        rightMargin: Appearance.px(3)
                        verticalCenter: parent.verticalCenter
                    }
                    text: taskRow.modelData.text
                    color: taskRow.modelData.completed
                        ? Appearance.subtext : Appearance.layer0Text
                    elide: Text.ElideRight
                    font {
                        family: Appearance.fontFamily
                        pixelSize: Appearance.px(11)
                        strikeout: taskRow.modelData.completed
                    }
                }

                MouseArea {
                    id: deleteButton

                    anchors {
                        right: parent.right
                        rightMargin: Appearance.px(4)
                        verticalCenter: parent.verticalCenter
                    }
                    width: Appearance.px(24)
                    height: Appearance.px(24)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    opacity: taskRow.containsMouse ? 1 : 0
                    onClicked: mouse => {
                        mouse.accepted = true;
                        TodoService.deleteTask(taskRow.modelData.id);
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: deleteButton.containsMouse
                            ? Theme.palette.m3error : Appearance.subtext
                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(13)
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                        }
                    }

                    Controls.ToolTip.visible: containsMouse
                    Controls.ToolTip.text: I18n.tr("delete")
                    Controls.ToolTip.delay: 500
                }
            }

            Text {
                anchors.centerIn: parent
                visible: TodoService.initialized
                    && TodoService.tasks.length === 0
                text: I18n.tr("noPendingTasks")
                color: Appearance.subtext
                font {
                    family: Appearance.fontFamily
                    pixelSize: Appearance.px(11)
                }
            }
        }
    }
}
