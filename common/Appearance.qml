pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Derived from the mutable Material 3 palette in Theme.qml.
    property color barBgColor: Theme.palette.m3background
    readonly property color barGlassBaseColor: "#080a0d"
    readonly property real barGlassTintOpacity: 0.68
    readonly property real popupGlassTintOpacity: 0.18
    readonly property real monochromeAppIconOpacity: 0.75
    readonly property color barSurfaceBaseColor:
        ShellSettings.barFrostedGlass
            ? barGlassBaseColor : barBgColor
    property color barSurfaceColor: ShellSettings.barFrostedGlass
        ? withAlpha(barGlassBaseColor, barGlassTintOpacity)
        : Theme.palette.m3background
    property color popupSurfaceColor: ShellSettings.barFrostedGlass
        ? barGlassBaseColor : Theme.palette.m3surfaceContainer
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

    // Bar-only palette. Glass mode is deliberately independent from Matugen;
    // the rest of the shell continues using the Material palette above.
    readonly property color barLayer0Text: ShellSettings.barFrostedGlass
        ? "#f5ffffff" : layer0Text
    readonly property color barLayer1Text: ShellSettings.barFrostedGlass
        ? "#d6ffffff" : layer1Text
    readonly property color barSubtext: ShellSettings.barFrostedGlass
        ? "#a6ffffff" : subtext
    readonly property color barOutline: ShellSettings.barFrostedGlass
        ? "#3dffffff" : outline
    readonly property color barLayer0Border: ShellSettings.barFrostedGlass
        ? "#33ffffff" : layer0Border
    readonly property color barLayer0: ShellSettings.barFrostedGlass
        ? "#52080a0d" : layer0
    readonly property color barLayer1: ShellSettings.barFrostedGlass
        ? "#18ffffff" : layer1
    readonly property color barLayer1Hover: ShellSettings.barFrostedGlass
        ? "#35ffffff" : layer1Hover
    readonly property color barLayer1Active: ShellSettings.barFrostedGlass
        ? "#48ffffff" : layer1Active
    readonly property color barLayer2: ShellSettings.barFrostedGlass
        ? "#20ffffff" : layer2
    readonly property color barLayer3: ShellSettings.barFrostedGlass
        ? "#2bffffff" : layer3
    readonly property color barPrimary: ShellSettings.barFrostedGlass
        ? "#edffffff" : primary
    readonly property color barOnPrimary: ShellSettings.barFrostedGlass
        ? "#f0000000" : Theme.palette.m3onPrimary
    readonly property color barPrimaryContainer:
        ShellSettings.barFrostedGlass ? "#3dffffff" : primaryContainer
    readonly property color barPrimaryContainerText:
        ShellSettings.barFrostedGlass ? "#f5ffffff" : primaryContainerText
    readonly property color barSecondaryContainer:
        ShellSettings.barFrostedGlass ? "#2effffff" : secondaryContainer
    readonly property color barSecondaryContainerText:
        ShellSettings.barFrostedGlass ? "#f5ffffff" : secondaryContainerText
    readonly property color barTertiary: ShellSettings.barFrostedGlass
        ? "#d9ffffff" : tertiary
    readonly property color barError: ShellSettings.barFrostedGlass
        ? "#ffff6b6b" : Theme.palette.m3error
    readonly property color barErrorContainer: ShellSettings.barFrostedGlass
        ? "#45ff6b6b" : Theme.palette.m3errorContainer
    readonly property color barOnError: ShellSettings.barFrostedGlass
        ? "#ffffffff" : Theme.palette.m3onError
    readonly property color barOnErrorContainer: ShellSettings.barFrostedGlass
        ? "#ffffdada" : Theme.palette.m3onErrorContainer
    readonly property color barShadow: ShellSettings.barFrostedGlass
        ? "#b3000000" : Theme.palette.m3shadow
    readonly property color barScrim: ShellSettings.barFrostedGlass
        ? "#8c000000" : Theme.palette.m3scrim

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
    readonly property int fontWeight: ShellSettings.fontWeight
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
