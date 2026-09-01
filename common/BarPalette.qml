pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    property bool enabled: true

    readonly property color layer0Text: enabled
        ? Appearance.barLayer0Text : Appearance.layer0Text
    readonly property color layer1Text: enabled
        ? Appearance.barLayer1Text : Appearance.layer1Text
    readonly property color subtext: enabled
        ? Appearance.barSubtext : Appearance.subtext
    readonly property color outline: enabled
        ? Appearance.barOutline : Appearance.outline
    readonly property color layer0Border: enabled
        ? Appearance.barLayer0Border : Appearance.layer0Border
    readonly property color layer0: enabled
        ? Appearance.barLayer0 : Appearance.layer0
    readonly property color layer1: enabled
        ? Appearance.barLayer1 : Appearance.layer1
    readonly property color layer1Hover: enabled
        ? Appearance.barLayer1Hover : Appearance.layer1Hover
    readonly property color layer1Active: enabled
        ? Appearance.barLayer1Active : Appearance.layer1Active
    readonly property color layer2: enabled
        ? Appearance.barLayer2 : Appearance.layer2
    readonly property color layer3: enabled
        ? Appearance.barLayer3 : Appearance.layer3
    readonly property color primary: enabled
        ? Appearance.barPrimary : Appearance.primary
    readonly property color onPrimary: enabled
        ? Appearance.barOnPrimary : Theme.palette.m3onPrimary
    readonly property color primaryContainer: enabled
        ? Appearance.barPrimaryContainer : Appearance.primaryContainer
    readonly property color primaryContainerText: enabled
        ? Appearance.barPrimaryContainerText
        : Appearance.primaryContainerText
    readonly property color secondaryContainer: enabled
        ? Appearance.barSecondaryContainer : Appearance.secondaryContainer
    readonly property color secondaryContainerText: enabled
        ? Appearance.barSecondaryContainerText
        : Appearance.secondaryContainerText
    readonly property color tertiary: enabled
        ? Appearance.barTertiary : Appearance.tertiary
    readonly property color error: enabled
        ? Appearance.barError : Theme.palette.m3error
    readonly property color errorContainer: enabled
        ? Appearance.barErrorContainer : Theme.palette.m3errorContainer
    readonly property color onError: enabled
        ? Appearance.barOnError : Theme.palette.m3onError
    readonly property color onErrorContainer: enabled
        ? Appearance.barOnErrorContainer : Theme.palette.m3onErrorContainer
    readonly property color shadow: enabled
        ? Appearance.barShadow : Theme.palette.m3shadow
    readonly property color scrim: enabled
        ? Appearance.barScrim : Theme.palette.m3scrim
}
