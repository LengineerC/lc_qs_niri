//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import qs.common
import qs.common.widgets

ShellRoot {
    Window {
        id: win
        visible: true
        width: 800
        height: 600
        Flickable {
            id: outer
            width: 350
            height: 550
            contentHeight: 1800
            clip: true
            property ScrollWheelHandler scrollWheel: ScrollWheelHandler {
                flickable: outer
            }
            Rectangle {
                width: 350
                height: 1800
                color: "lightgrey"
            }
            Flickable {
                id: inner
                x: 20
                y: 100
                width: 250
                height: 200
                contentHeight: 900
                clip: true
                property ScrollWheelHandler scrollWheel: ScrollWheelHandler {
                    flickable: inner
                }
                Rectangle {
                    width: 250
                    height: 900
                    color: "lightblue"
                }
            }
        }
        ScrollView {
            id: view
            x: 400
            width: 350
            height: 550
            contentWidth: 350
            contentHeight: 1800
            property ScrollWheelHandler scrollWheel: ScrollWheelHandler {
                flickable: view.contentItem
                allowNonInteractive: true
            }
            Rectangle {
                width: 350
                height: 1800
                color: "lightgreen"
            }
        }
        ListView {
            id: list
            x: 0
            y: 0
            width: 350
            height: 550
            visible: false
            clip: true
            model: 100
            delegate: Rectangle {
                required property int index
                width: 350
                height: 40
                color: index % 2 ? "grey" : "white"
            }
            property ScrollWheelHandler scrollWheel: ScrollWheelHandler {
                flickable: list
            }
        }
        GridView {
            id: grid
            x: 400
            width: 350
            height: 550
            visible: false
            clip: true
            cellWidth: 100
            cellHeight: 60
            model: 100
            delegate: Rectangle {
                width: 90
                height: 50
                color: "lightgrey"
            }
            property ScrollWheelHandler scrollWheel: ScrollWheelHandler {
                flickable: grid
            }
        }
        TestCase {
            name: "ScrollSpeed"
            when: win.visible
            function test_scroll() {
                wait(200);
                const step = 20 * Qt.styleHints.wheelScrollLines * Appearance.wheelScrollMultiplier;
                mouseWheel(outer, 10, 10, 0, -120);
                wait(200);
                compare(outer.contentY, step);
                outer.contentY = 0;
                mouseWheel(inner, 50, 50, 0, -120);
                wait(200);
                compare(inner.contentY, step);
                compare(outer.contentY, 0);
                inner.contentY = 700;
                mouseWheel(inner, 50, 50, 0, -120);
                wait(200);
                compare(inner.contentY, 700);
                compare(outer.contentY, step);
                mouseWheel(view, 50, 50, 0, -120);
                wait(200);
                compare(view.contentItem.contentY, step);
                const handler = view.scrollWheel;
                handler.scroll({
                    pixelDelta: Qt.point(0, -20),
                    angleDelta: Qt.point(0, 0),
                    accepted: false
                });
                compare(view.contentItem.contentY, step + 20 * Appearance.touchpadScrollMultiplier);
                view.contentItem.contentY = 0;
                mouseWheel(view, 50, 50, 0, -120);
                mouseWheel(view, 50, 50, 0, -120);
                wait(200);
                compare(view.contentItem.contentY, step * 2);
                outer.visible = false;
                view.visible = false;
                list.visible = true;
                grid.visible = true;
                wait(100);
                mouseWheel(list, 50, 50, 0, -120);
                wait(200);
                compare(list.contentY, step);
                mouseWheel(grid, 50, 50, 0, -120);
                wait(200);
                compare(grid.contentY, step);
                list.interactive = false;
                mouseWheel(list, 50, 50, 0, -120);
                wait(200);
                compare(list.contentY, step);
                console.log('SCROLL_WHEEL_TEST_PASSED');
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        onTriggered: Qt.quit()
    }
}
