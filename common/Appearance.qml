pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Derived from the mutable Material 3 palette in Theme.qml.
    property color barBgColor: Theme.palette.m3background
    readonly property real barGlassTintOpacity:
        Theme.darkMode ? 0.42 : 0.52
    readonly property real popupGlassTintOpacity:
        Theme.darkMode ? 0.18 : 0.14
    property color barSurfaceColor: ShellSettings.barFrostedGlass
        ? withAlpha(Theme.palette.m3background,
            barGlassTintOpacity)
        : Theme.palette.m3background
    property color popupSurfaceColor: Theme.palette.m3surfaceContainer
    property color layer0: Theme.palette.m3background
    property color layer0Border: mix(Theme.palette.m3outlineVariant,
        Theme.palette.m3background, 0.4)
    property color layer1: Theme.palette.m3surfaceContainerLow
    property color layer1Hover: mix(Theme.palette.m3surfaceContainerLow,
        Theme.palette.m3onSurfaceVariant, 0.08)
    property color layer1Active: mix(Theme.palette.m3surfaceContainerLow,
        Theme.palette.m3onSurfaceVariant, 0.15)
    property color layer2: Theme.palette.m3surfaceContainer
    property color layer3: Theme.palette.m3surfaceContainerHigh
    property color layer0Text: Theme.palette.m3onBackground
    property color layer1Text: Theme.palette.m3onSurfaceVariant
    property color subtext: Theme.palette.m3outline
    property color outline: Theme.palette.m3outlineVariant
    property color primary: Theme.palette.m3primary
    property color primaryContainer: Theme.palette.m3primaryContainer
    property color primaryContainerText: Theme.palette.m3onPrimaryContainer
    property color secondaryContainer: Theme.palette.m3secondaryContainer
    property color secondaryContainerText: Theme.palette.m3onSecondaryContainer
    property color tertiary: Theme.palette.m3tertiary
    property color shadow: withAlpha(Theme.palette.m3shadow, 0.7)

    function mix(first, second, amount) {
        return Qt.rgba(
            first.r * (1 - amount) + second.r * amount,
            first.g * (1 - amount) + second.g * amount,
            first.b * (1 - amount) + second.b * amount,
            first.a * (1 - amount) + second.a * amount
        );
    }

    function withAlpha(colorValue, alpha) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, alpha);
    }

    function px(value) {
        return Math.max(1, Math.round(value * ShellSettings.scale));
    }

    readonly property real scale: ShellSettings.scale
    readonly property string fontFamily: ShellSettings.barFontFamily
    readonly property string monospaceFontFamily:
        ShellSettings.monospaceFontFamily
    readonly property string iconFontFamily: "Symbols Nerd Font"
    readonly property int fontSize: Math.max(8,
        Math.round(ShellSettings.barFontSize * scale))
    readonly property int smallFontSize: Math.max(7, fontSize - px(2))
    readonly property int largeFontSize: fontSize + px(3)

    readonly property int barHeight: px(40)
    readonly property int cornerSize: px(23)
    readonly property int smallRadius: px(12)
    readonly property int normalRadius: px(17)
    readonly property int fullRadius: 9999
    readonly property int elevationMargin: px(10)

    readonly property int fastDuration: Math.max(40,
        Math.round(ShellSettings.animationDuration * 0.4))
    readonly property int spatialDuration: ShellSettings.animationDuration
    readonly property var fastCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
    readonly property var spatialCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
    readonly property var exitCurve: [0.3, 0, 0.8, 0.15, 1, 1]

    Behavior on barBgColor { ColorAnimation { duration: root.spatialDuration } }
    Behavior on barSurfaceColor { ColorAnimation { duration: root.spatialDuration } }
    Behavior on popupSurfaceColor { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer0 { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer0Border { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer1 { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer1Hover { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer1Active { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer2 { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer3 { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer0Text { ColorAnimation { duration: root.spatialDuration } }
    Behavior on layer1Text { ColorAnimation { duration: root.spatialDuration } }
    Behavior on subtext { ColorAnimation { duration: root.spatialDuration } }
    Behavior on outline { ColorAnimation { duration: root.spatialDuration } }
    Behavior on primary { ColorAnimation { duration: root.spatialDuration } }
    Behavior on primaryContainer { ColorAnimation { duration: root.spatialDuration } }
    Behavior on primaryContainerText { ColorAnimation { duration: root.spatialDuration } }
    Behavior on secondaryContainer { ColorAnimation { duration: root.spatialDuration } }
    Behavior on secondaryContainerText { ColorAnimation { duration: root.spatialDuration } }
    Behavior on tertiary { ColorAnimation { duration: root.spatialDuration } }
    Behavior on shadow { ColorAnimation { duration: root.spatialDuration } }
}
