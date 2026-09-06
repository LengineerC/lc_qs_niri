pragma ComponentBehavior: Bound

import QtQuick
import qs.common

PopupHeader {
    showCloseButton: true
    showDivider: true
    headerRowHeight: Appearance.controlHeight
    iconSize: Appearance.px(20)
    iconSlotSize: Appearance.px(20)
    titleFontSize: Appearance.largeFontSize
    titleFontWeight: Font.DemiBold
    contentSpacing: Appearance.spacingSmall
    dividerSpacing: Appearance.spacingTiny
    dividerOpacity: 1
}
