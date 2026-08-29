pragma Singleton
import QtQuick

QtObject {
    property color g0: "#1d2021"   // bg0_h (hard)
    property color g1: "#3c3836"   // bg1
    property color g2: "#504945"   // bg2
    property color g3: "#665c54"   // bg3
    property color g4: "#bdae93"   // fg3
    property color g5: "#ebdbb2"   // fg1
    property color g6: "#d5c4a1"   // fg2
    property color g7: "#8ec07c"   // bright_aqua
    property color g8: "#689d6a"   // neutral_aqua
    property color g9: "#83a598"   // bright_blue
    property color g10: "#458588"  // neutral_blue
    property color g11: "#fb4934"  // bright_red
    property color g12: "#fe8019"  // bright_orange
    property color g13: "#fabd2f"  // bright_yellow
    property color g14: "#b8bb26"  // bright_green
    property color g15: "#d3869b"  // bright_purple
    // extras
    property color g16: "#282828"  // bg0
    property color g17: "#7c6f64"  // bg4
    property color g18: "#928374"  // gray
    property color g19: "#a89984"  // fg4
    property color g20: "#fbf1c7"  // fg0

    property color colFg: g5
    property color colFgDim: g4
    property color colBg: g0
    property color colBgAlt: g1
    property color colBgSec: g1
    property color colSelected: g6
    property color colHoverAlpha: Qt.rgba(0x66 / 255, 0x5c / 255, 0x54 / 255, 0.8)
    property color colHoverSolid: g4
    property color colAccent: g2
    property color colUrgent: g11
    property color colCritical: g11
    property color colBorder: Qt.rgba(0x66 / 255, 0x5c / 255, 0x54 / 255, 0.45)
    property color colBorderStrong: Qt.rgba(0x66 / 255, 0x5c / 255, 0x54 / 255, 0.65)
    property color colDndChecked: g10
    property color colActionBg: Qt.rgba(0xd5 / 255, 0xc4 / 255, 0xa1 / 255, 0.55)
    property color colShadow: Qt.rgba(0x1d / 255, 0x20 / 255, 0x21 / 255, 0.45)
    property color colMeterBg: Qt.rgba(0x50 / 255, 0x49 / 255, 0x45 / 255, 0.9)
    property color colMeterFg: g5
    property color colMuted: g4
    property color colBgAlpha095: Qt.rgba(0x1d / 255, 0x20 / 255, 0x21 / 255, 0.95)
    property color colBgAlpha085: Qt.rgba(0x1d / 255, 0x20 / 255, 0x21 / 255, 0.85)
    property color colBgAlpha078: Qt.rgba(0x1d / 255, 0x20 / 255, 0x21 / 255, 0.78)
    property string fontFamily: "JetBrainsMono NF"
    property color colLauncherBg: Qt.rgba(0x1d / 255, 0x20 / 255, 0x21 / 255, 0.88)
    property color colLauncherBorder: Qt.rgba(0x7c / 255, 0x6f / 255, 0x64 / 255, 0.35)
    property color colInputBg: Qt.rgba(0x3c / 255, 0x38 / 255, 0x36 / 255, 0.65)
    property color colChipBg: Qt.rgba(0x50 / 255, 0x49 / 255, 0x45 / 255, 0.9)
    property color colChipActive: g6
    property string fontFallback: "Nerd Font"
    property int fontSize: 15
}
