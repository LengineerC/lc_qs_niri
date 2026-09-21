pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    readonly property bool glassMode: ShellSettings.barFrostedGlass

    // A darker common tint keeps a large settings window readable while the
    // translucent child surfaces still reveal the compositor blur below it.
    readonly property color window: glassMode
        ? Appearance.withAlpha(Appearance.barGlassBaseColor, 0.62)
        : Appearance.layer0
    readonly property color windowSheen: glassMode
        ? Appearance.withAlpha("#ffffff", 0.055) : "transparent"

    readonly property color layer0Text: glassMode
        ? Appearance.barLayer0Text : Appearance.layer0Text
    readonly property color layer1Text: glassMode
        ? Appearance.barLayer1Text : Appearance.layer1Text
    readonly property color subtext: glassMode
        ? Appearance.barSubtext : Appearance.subtext
    readonly property color outline: glassMode
        ? Appearance.barOutline : Appearance.outline
    readonly property color layer0Border: glassMode
        ? Appearance.barLayer0Border : Appearance.layer0Border
    readonly property color layer0: glassMode
        ? Appearance.barLayer0 : Appearance.layer0
    readonly property color layer1: glassMode
        ? Appearance.barLayer1 : Appearance.layer1
    readonly property color layer1Hover: glassMode
        ? Appearance.barLayer1Hover : Appearance.layer1Hover
    readonly property color layer1Active: glassMode
        ? Appearance.barLayer1Active : Appearance.layer1Active
    readonly property color layer2: glassMode
        ? Appearance.barLayer2 : Appearance.layer2
    readonly property color layer3: glassMode
        ? Appearance.barLayer3 : Appearance.layer3
    readonly property color primary: glassMode
        ? Appearance.barPrimary : Appearance.primary
    readonly property color onPrimary: glassMode
        ? Appearance.barOnPrimary : Theme.palette.m3onPrimary
    readonly property color primaryContainer: glassMode
        ? Appearance.barPrimaryContainer : Appearance.primaryContainer
    readonly property color primaryContainerText: glassMode
        ? Appearance.barPrimaryContainerText
        : Appearance.primaryContainerText
    readonly property color secondaryContainer: glassMode
        ? Appearance.barSecondaryContainer : Appearance.secondaryContainer
    readonly property color secondaryContainerText: glassMode
        ? Appearance.barSecondaryContainerText
        : Appearance.secondaryContainerText
    readonly property color error: glassMode
        ? Appearance.barError : Theme.palette.m3error
    readonly property color errorContainer: glassMode
        ? Appearance.barErrorContainer : Theme.palette.m3errorContainer
    readonly property color onErrorContainer: glassMode
        ? Appearance.barOnErrorContainer : Theme.palette.m3onErrorContainer
    readonly property color scrim: glassMode
        ? Appearance.barScrim : Theme.palette.m3scrim
}
