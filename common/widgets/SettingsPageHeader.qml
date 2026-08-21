pragma ComponentBehavior: Bound

import QtQuick
import qs.common

PopupHeader {
    showCloseButton: true
    showDivider: true
    headerRowHeight: Appearance.px(34)
    iconSize: Appearance.px(20)
    iconSlotSize: Appearance.px(20)
    titleFontSize: Appearance.largeFontSize
    titleFontWeight: Font.DemiBold
    contentSpacing: Appearance.px(9)
    dividerSpacing: Appearance.px(4)
    dividerOpacity: 1
}
