pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.common
import qs.services

Item {
    id: root

    property real implicitSize: Appearance.px(64)
    property url source: UserService.avatarUrl
    property real imageInset: 1

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Appearance.primaryContainer

        Text {
            anchors.centerIn: parent
            text: "󰀄"
            color: Appearance.primaryContainerText
            font {
                family: Appearance.iconFontFamily
                pixelSize: root.width * 0.48
            }
        }
    }

    Image {
        id: avatarImage

        anchors {
            fill: parent
            margins: root.imageInset
        }
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        visible: source !== ""
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: avatarMask
        }
    }

    Rectangle {
        id: avatarMask

        width: avatarImage.width
        height: avatarImage.height
        radius: width / 2
        visible: false
        layer.enabled: true
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Appearance.outline
    }
}
