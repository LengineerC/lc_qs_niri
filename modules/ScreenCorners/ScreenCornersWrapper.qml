pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData

        screen: modelData
        visible: ShellSettings.screenCornersEnabled
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:screen-corners"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        ScreenCorners {
            outputName: modelData.name
        }

        mask: Region {
        }

    }

}
