import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData

        screen: modelData
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        ScreenCorners {
        }

        mask: Region {
        }

    }

}
